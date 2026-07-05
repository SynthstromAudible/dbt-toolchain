# Design: Split dbt-toolchain CI into a fast lane and a build/release lane

**Date:** 2026-07-05
**Status:** Approved (design); implementation plan to follow.

## Problem

`.github/workflows/release.yml` is the repo's single catch-all workflow. Despite
the name it runs on **every push to `main` and every PR** (plus `create`), as one
sequential job that does four jobs' worth of work:

1. **Test** — `pip install .[dev]` → `pytest` (fast, seconds).
2. **Build** — `dbtbuilder` downloads every toolchain and builds all platform
   tarballs (heavy — hundreds of MB, minutes).
3. **Docker image** — builds the CI image, which clones firmware `main` and runs
   `./dbt build` as a smoke test (very heavy, QEMU).
4. **Publish** — GHCR push + GitHub release, the only part gated to `refs/tags/`.

Consequences: unit-test feedback is stuck behind (and in the same job as) the
heavy toolchain + Docker build; a red `pytest` and a broken toolchain build are
indistinguishable at the workflow level; there is no fast PR signal; and the
workflow name is a misnomer (only step 4 is "release"). CI also never runs `ruff`,
though `pyproject.toml` already carries ruff config.

## Goal

Separate fast checks from the heavy build so PRs get quick, unambiguous feedback,
and give the heavy build/publish workflow an honest name and trigger set.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Heavy lane triggers | **main + tags only** — no PR runs. PRs get fast checks only. |
| Fast lane checks | **ruff + pytest** (`ruff check .`, `ruff format --check .`, `pytest`). |
| Naming | **Rename `release.yml` → `build.yml`** (`name: Build and Release`). |

Accepted trade-off: toolchain-build and firmware-compat breakage is caught on
push-to-main, not on the PR. dbt-toolchain PRs are rare, so this is an acceptable
cost for fast PR feedback.

## Preconditions found during design

- `ruff check .` already passes (lint clean).
- `ruff format --check .` reports **13 files would be reformatted**. Adding the
  format check to CI therefore requires a one-time `ruff format .` normalization
  first, or CI is red on arrival. This is done as its own isolated commit so the
  reformat noise stays separate from the workflow change.

## Changes

### 1. `pyproject.toml`

Add a pinned ruff to the dev extras so the CI format check cannot drift when ruff
changes its formatting style between releases:

```toml
[project.optional-dependencies]
dev = ["pytest>=8", "ruff==0.15.20"]
```

### 2. Formatting normalization

Run `ruff format .` across the tree (13 files under `src/` and `tests/`), committed
on its own. `ruff format` is deterministic and semantics-preserving. After this,
`ruff format --check .` passes.

### 3. New `.github/workflows/ci.yml` (fast lane)

Runs on push-to-main and PRs. No `prepare.sh` (apt) — lint and tests only need pip,
so this lane is genuinely fast.

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install dbtbuilder
        run: pip3 install ".[dev]"
      - name: Ruff lint
        run: ruff check .
      - name: Ruff format check
        run: ruff format --check .
      - name: Unit tests
        run: python3 -m pytest
```

### 4. Rename `release.yml` → `build.yml` (heavy lane)

`git mv` the file, then modify it. Diff from the current `release.yml`:

- Add `name: Build and Release`.
- Triggers: keep `push.branches: [main]` and `create`; **remove** the
  `pull_request` block (no PR runs).
- Remove the `Run unit tests` step (`python3 -m pytest`) — now in `ci.yml`.
- Change `Install dbtbuilder` from `pip3 install ".[dev]"` to `pip3 install .`
  (the build needs only runtime deps).
- Everything else is unchanged: `prepare.sh`, `dbtbuilder` build, QEMU/buildx, the
  Docker smoke image build, and the tag-gated GHCR push + GitHub release.

`create` is retained (not replaced with `push.tags`) to preserve the current
tag-publish trigger behaviour exactly; the publish steps stay gated on
`startsWith(github.ref, 'refs/tags/')`.

### 5. `.gitignore`

Add `.ruff_cache/` if not already ignored.

## Net behavior

| Event | `ci.yml` | `build.yml` |
|---|---|---|
| PR to main | ruff + pytest | — |
| Push to main | ruff + pytest | build + Docker smoke (no publish) |
| Tag `v*` | — | build + Docker smoke + **publish** |

## Testing / verification

- Both workflow files parse as YAML; run `actionlint` if available.
- After normalization, `ruff check .`, `ruff format --check .`, and
  `python3 -m pytest` are all green locally (the exact commands `ci.yml` runs).
- The workflows themselves can only be exercised by GitHub Actions on push; that
  is the authoritative check and is out of local scope.

## Out of scope

- Splitting the heavy lane's toolchain build from its Docker smoke build into
  separate jobs with artifact passing (YAGNI — the Docker build consumes the
  build's `dist/` tarball; one job is simpler).
- Changing the firmware branch the Docker smoke build tracks (already `main`).
- The DelugeFirmware-side `test_dbtenv_rust.sh` CI wiring (a separate repo/topic).
