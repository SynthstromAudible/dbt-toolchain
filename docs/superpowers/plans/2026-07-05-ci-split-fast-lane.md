# CI Split (Fast Lane + Build/Release) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the single catch-all `release.yml` into a fast lane (`ci.yml`: ruff + pytest on every PR/push) and a heavy build/release lane (`build.yml`: toolchain build + Docker smoke + tag-gated publish, on main/tags only).

**Architecture:** First enable ruff in CI — pin it in the `[dev]` extras and normalize the tree with `ruff format` so the format check is green. Then add `ci.yml` for fast checks and `git mv release.yml build.yml`, stripping the now-duplicated test step and the PR trigger from the heavy lane.

**Tech Stack:** GitHub Actions (YAML), ruff, pytest, the `dbtbuilder` package.

## Global Constraints

- **Ruff is pinned:** `ruff==0.15.20` in `[project.optional-dependencies] dev` (so the CI format check can't drift when ruff changes its style).
- **Fast lane checks, in order:** `ruff check .`, `ruff format --check .`, `python3 -m pytest`.
- **Heavy lane triggers:** `push` to `main` and `create` only. **No `pull_request`.** Publish steps stay gated on `startsWith(github.ref, 'refs/tags/')`.
- **Heavy lane (`build.yml`) is otherwise byte-identical to today's `release.yml`** except: add `name: Build and Release`, drop the `pull_request` trigger, remove the `Run unit tests` step, and change `Install dbtbuilder` to `pip3 install .`. Do NOT touch the toolchain build, QEMU/buildx, Docker smoke build, or the tag-gated GHCR push / GitHub release steps.
- **`ruff format` is deterministic and semantics-preserving**; the normalization commit changes formatting only, no logic.
- Local ruff runs use the repo venv: `.venv/bin/ruff` (create/refresh via `.venv/bin/pip install -e ".[dev]"`). Tests: `.venv/bin/python -m pytest`.
- Do NOT bump `config.toml` `version`; do NOT create git tags.

## File map

| File | Change | Task |
|---|---|---|
| `pyproject.toml` | add `ruff==0.15.20` to `[dev]` | 1 |
| `.gitignore` | ignore `.ruff_cache/` | 1 |
| `src/**`, `tests/**` (13 files) | `ruff format` normalization | 1 |
| `.github/workflows/ci.yml` | new fast lane | 2 |
| `.github/workflows/build.yml` | renamed from `release.yml`, retriggered | 2 |

---

### Task 1: Enable ruff and normalize formatting

**Files:**
- Modify: `pyproject.toml` (`[project.optional-dependencies]`)
- Modify: `.gitignore`
- Modify: 13 files under `src/dbtbuilder/` and `tests/` (via `ruff format`)

**Interfaces:**
- Produces: a tree where `.venv/bin/ruff check .`, `.venv/bin/ruff format --check .`, and `.venv/bin/python -m pytest` all exit 0; `ruff==0.15.20` available through the `[dev]` extras (consumed by `ci.yml` in Task 2).

- [ ] **Step 1: Pin ruff in the dev extras**

In `pyproject.toml`, replace:

```toml
[project.optional-dependencies]
dev = ["pytest>=8"]
```

with:

```toml
[project.optional-dependencies]
dev = ["pytest>=8", "ruff==0.15.20"]
```

- [ ] **Step 2: Ignore the ruff cache**

In `.gitignore`, replace:

```
__pycache__/
*.egg-info/
.venv/
.pytest_cache/
```

with:

```
__pycache__/
*.egg-info/
.venv/
.pytest_cache/
.ruff_cache/
```

- [ ] **Step 3: Install the dev extras (gets ruff into the venv)**

Run:
```bash
.venv/bin/pip install -q -e ".[dev]"
.venv/bin/ruff --version
```
Expected: prints `ruff 0.15.20`.

- [ ] **Step 4: Confirm the pre-normalization state**

Run:
```bash
.venv/bin/ruff check .
.venv/bin/ruff format --check .
```
Expected: `ruff check` prints `All checks passed!` (exit 0). `ruff format --check` lists ~13 files under `src/` and `tests/` as "Would reformat" and exits non-zero. This is the state Step 5 fixes.

- [ ] **Step 5: Normalize formatting**

Run:
```bash
.venv/bin/ruff format .
```
Expected: reports "N files reformatted" (~13).

- [ ] **Step 6: Verify everything is green**

Run:
```bash
.venv/bin/ruff check .
.venv/bin/ruff format --check .
.venv/bin/python -m pytest -q
```
Expected: `ruff check` → `All checks passed!`; `ruff format --check` → `N files already formatted` (exit 0, no "Would reformat"); pytest → all tests pass.

- [ ] **Step 7: Commit the config change and the normalization separately**

Two commits so the reformat noise stays isolated from the config change:

```bash
git add pyproject.toml .gitignore
git commit -m "Add ruff to dev deps and ignore its cache"

git add src tests
git commit -m "Normalize formatting with ruff format"
```

---

### Task 2: Split the workflow into `ci.yml` and `build.yml`

**Files:**
- Create: `.github/workflows/ci.yml`
- Rename + modify: `.github/workflows/release.yml` → `.github/workflows/build.yml`

**Interfaces:**
- Consumes: the `[dev]` extras from Task 1 (`ci.yml` runs `ruff` and `pytest`, both provided by `pip install .[dev]`).
- Produces: `ci.yml` (fast checks on PR + push-main) and `build.yml` (heavy build + tag-gated publish on push-main + `create`).

- [ ] **Step 1: Create the fast lane `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches:
      - 'main'
  pull_request:
    branches:
      - 'main'

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repo
        uses: actions/checkout@v4
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

- [ ] **Step 2: Rename the heavy workflow**

Run:
```bash
git mv .github/workflows/release.yml .github/workflows/build.yml
```

- [ ] **Step 3: Add the workflow name and drop the PR trigger**

In `.github/workflows/build.yml`, replace the top of the file:

```yaml
on:
  push:
    branches:
      - 'main'
  create:
  pull_request:
    branches:
      - 'main'

env:
```

with:

```yaml
name: Build and Release

on:
  push:
    branches:
      - 'main'
  create:

env:
```

- [ ] **Step 4: Remove the now-duplicated test step**

In `.github/workflows/build.yml`, replace:

```yaml
      - name: Install dbtbuilder
        run: pip3 install ".[dev]"
      - name: Run unit tests
        run: python3 -m pytest
      - name: Set up QEMU
```

with:

```yaml
      - name: Install dbtbuilder
        run: pip3 install .
      - name: Set up QEMU
```

- [ ] **Step 5: Static-verify both workflows**

Run:
```bash
cd /home/kate/GitHub/dbt-toolchain
echo "--- build.yml: no PR trigger, no pytest, has name, runtime-only install ---"
grep -n "pull_request\|Run unit tests\|python3 -m pytest" .github/workflows/build.yml || echo "OK: none present"
grep -n "name: Build and Release" .github/workflows/build.yml
grep -n 'run: pip3 install \.$' .github/workflows/build.yml
echo "--- build.yml still has the heavy + publish steps ---"
grep -n "Run build\|Build and push Docker images\|Push release\|DELUGE_SRC_BRANCH=main" .github/workflows/build.yml
echo "--- ci.yml has the three checks ---"
grep -n "ruff check\|ruff format --check\|python3 -m pytest" .github/workflows/ci.yml
echo "--- release.yml is gone ---"
test ! -e .github/workflows/release.yml && echo "OK: release.yml removed"
echo "--- YAML/actionlint validation ---"
if command -v actionlint >/dev/null 2>&1; then
  actionlint .github/workflows/ci.yml .github/workflows/build.yml && echo "actionlint OK"
elif python3 -c "import yaml" 2>/dev/null; then
  python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]; print('YAML OK')" .github/workflows/ci.yml .github/workflows/build.yml
else
  echo "actionlint/PyYAML not available; skipping schema check (GitHub validates on push)"
fi
```
Expected: `build.yml` shows no `pull_request` / `Run unit tests` / `python3 -m pytest` matches (prints `OK: none present`); shows `name: Build and Release` and `run: pip3 install .`; still shows the `Run build`, Docker push, `Push release`, and `DELUGE_SRC_BRANCH=main` lines; `ci.yml` shows the three check commands; `release.yml` is removed; and the YAML/actionlint check passes (or is explicitly skipped).

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/build.yml
git commit -m "Split CI: fast ci.yml (ruff + pytest) and build.yml (build + tag publish)

ci.yml runs ruff and pytest on every PR and push to main. release.yml is renamed
to build.yml, loses the PR trigger and the duplicated test step, and installs
runtime-only deps; it still builds the toolchains, smoke-builds the Docker CI
image, and publishes to GHCR + GitHub Releases on tags."
```

---

## Notes for the implementer

- **Why two commits in Task 1:** `ruff format` touches 13 files; keeping that diff separate from the one-line `pyproject.toml`/`.gitignore` change keeps history readable and makes the config change easy to review.
- **You cannot run the workflows locally.** GitHub Actions runs them on push. Local verification is limited to: the exact commands `ci.yml` runs (green after Task 1), YAML/actionlint validity, and the grep assertions in Task 2 Step 5.
- **First real run of `build.yml`** (on the next push to `main` or tag) still smoke-builds firmware `main` inside the Docker image — that can fail loudly if firmware `main` isn't ready for the current toolchain version, which is the intended signal from the earlier CI-image change, not a defect in this split.
- **Do not** re-introduce a `pull_request` trigger on `build.yml` — the whole point is that PRs run only the fast lane.
