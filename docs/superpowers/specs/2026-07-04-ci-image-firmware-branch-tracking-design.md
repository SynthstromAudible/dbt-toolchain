# Design: Track firmware `main` in the CI-image smoke build

**Date:** 2026-07-04
**Status:** Approved (design); implementation plan to follow.

## Problem

The CI-image build (`actions-support/ci-image/Dockerfile`, `builder` stage) smoke-tests
a freshly built toolchain by cloning DelugeFirmware, checking out a **hard-pinned commit**
`DELUGE_SRC_COMMIT=ae9f3996`, and running `./dbt build`. A gate asserts the firmware's
`toolchain/REQUIRED_VERSION` equals this toolchain's `DBT_VERSION`, failing otherwise with
a comment instructing the maintainer to "edit `DELUGE_SRC_COMMIT` to point to a commit that
bumps `REQUIRED_VERSION`."

Every toolchain version bump therefore requires a manual chore: find (or wait for) a
DelugeFirmware commit whose `REQUIRED_VERSION` matches the new toolchain, then update the
pinned hash here. This is a recurring source of "Update commit for docker smoke test"
commits and a chicken-and-egg wait (the new toolchain isn't referenced by firmware yet).

A half-finished intent already exists: `release.yml` passes a `DELUGE_SRC_BRANCH=community`
build-arg that the Dockerfile never declares, so it is silently ignored.

## Goal

Replace the pinned-commit chore with **branch-tip tracking + an automatic version
override**: clone firmware `main` at its current tip and force
`toolchain/REQUIRED_VERSION` to the toolchain version we just built, so the smoke build
always exercises firmware HEAD against exactly this toolchain — with no per-release manual
edit.

## Non-goals

- No patch-file machinery. The mechanism is a version overwrite only (chosen deliberately;
  see "Decisions"). If firmware HEAD needs *source* changes to build a new toolchain, the
  smoke build fails loudly rather than carrying a patch.
- No change to the toolchain build itself, the final image, or the unpack stage.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Version mechanism | **Echo only** — overwrite `toolchain/REQUIRED_VERSION` with `$DBT_VERSION`. No patch dir/file. |
| Firmware ref | **`main` branch tip** (replaces the pinned commit). Org stays overridable. |

## Changes

### `actions-support/ci-image/Dockerfile` (builder stage)

1. Replace `ARG DELUGE_SRC_COMMIT=ae9f3996` and the stale `# top-of-tree as of 2026-06-25`
   comment with `ARG DELUGE_SRC_BRANCH=main`. Keep `ARG DELUGE_SRC_ORG=synthstromaudible`.
2. In the `GIT_CHECKOUT` heredoc, ensure the working tree is the branch tip even when the
   `--mount=type=cache` clone is warm:
   ```bash
   git clone --branch $DELUGE_SRC_BRANCH https://github.com/$DELUGE_SRC_ORG/DelugeFirmware.git /tmp/git_cache/DelugeFirmware || true
   cd /tmp/git_cache/DelugeFirmware/
   git fetch origin $DELUGE_SRC_BRANCH
   git reset --hard origin/$DELUGE_SRC_BRANCH
   mkdir -p /build
   cp -r ./* ./.git/ /build/
   ```
   (Drops `git checkout ${DELUGE_SRC_COMMIT}`.)
3. In the `SMOKE_BUILD` heredoc, **delete** the version-gate block (the
   `required_version=$(<toolchain/REQUIRED_VERSION)` read, the mismatch `exit 1`, and the
   "edit DELUGE_SRC_COMMIT…" comment). Immediately after `cd /build`, force the version:
   ```bash
   cd /build
   # Smoke-test firmware HEAD against exactly the toolchain we just built.
   echo "$DBT_VERSION" > toolchain/REQUIRED_VERSION
   case "$TARGETARCH" in
     amd64) ./dbt build ;;
     arm64) ./dbt configure ;;
     ...
   ```

### `.github/workflows/release.yml`

Change the existing build-arg value `DELUGE_SRC_BRANCH=community` → `DELUGE_SRC_BRANCH=main`
so it is honored (the Dockerfile now declares the ARG) and matches the new default.

### `actions-support/simulate_ci_image_build.sh`

Update the Dockerfile scrape on line 24 from `^ARG DELUGE_SRC_COMMIT=` to
`^ARG DELUGE_SRC_BRANCH=` so local buildx runs pass the branch through the same way the
`DELUGE_SRC_ORG` line already does.

## Consequences (all intended)

- **Non-deterministic smoke input.** The build tracks a moving `main` tip, not a frozen
  commit. This is the objective — it removes the recurring manual commit-bump.
- **Loud coupling to firmware `main`.** If a new toolchain needs firmware source changes not
  yet on `main` (e.g. rustup wiring), `./dbt build` fails and CI goes red. Echo-only has no
  patch escape hatch — the accepted trade-off. The failure is a true signal that the
  toolchain cannot yet build current firmware.
- **Docker layer-cache caveat.** CI's `build-push-action` configures no persistent layer
  cache, so the `GIT_CHECKOUT` RUN re-executes and re-fetches each run — branch-tracking
  works. A warm *local* daemon cache could skip it; pass `--no-cache` for a guaranteed-fresh
  local run. (A cache-bust ARG could be added later if this becomes a pain; not now.)

## Verification

- Static: `bash -n` the `GIT_CHECKOUT` and `SMOKE_BUILD` heredoc bodies to catch shell
  syntax errors; confirm no remaining `DELUGE_SRC_COMMIT` / `REQUIRED_VERSION`-gate
  references across the repo.
- End-to-end (heavy; may be deferred to CI on push): `./actions-support/simulate_ci_image_build.sh`
  builds the image, clones firmware `main`, overwrites `REQUIRED_VERSION` to the current
  toolchain version, and runs `./dbt build` (amd64). Success = the smoke build completes
  against firmware HEAD with no pinned commit.
