# CI-Image Firmware Branch Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the CI-image smoke build track DelugeFirmware `main` at its current tip and force `toolchain/REQUIRED_VERSION` to the toolchain version being built, eliminating the manual "update the pinned firmware commit" chore.

**Architecture:** In `actions-support/ci-image/Dockerfile`'s `builder` stage, replace the hard-pinned `DELUGE_SRC_COMMIT` with a `DELUGE_SRC_BRANCH=main` ARG, clone that branch tip (with a `git reset --hard origin/$BRANCH` to defeat the warm build-cache clone), delete the `REQUIRED_VERSION`-vs-`DBT_VERSION` gate, and overwrite `toolchain/REQUIRED_VERSION` with `$DBT_VERSION` right before `./dbt build`. Update the two callers (`release.yml`, `simulate_ci_image_build.sh`) to pass the branch instead of a commit.

**Tech Stack:** Docker (buildx, `dockerfile:1-labs` heredoc syntax), GitHub Actions, bash, git.

## Global Constraints

- **Mechanism is echo-only.** After checkout, set the version with `echo "$DBT_VERSION" > toolchain/REQUIRED_VERSION`. No patch file / patch dir. If firmware `main` needs source changes to build a new toolchain, the smoke build is *expected* to fail loudly.
- **Firmware ref is the `main` branch tip**, via `ARG DELUGE_SRC_BRANCH=main`. `ARG DELUGE_SRC_ORG=synthstromaudible` stays overridable.
- **Docker heredoc substitution rule (do not break it):** in these `RUN <<NAME bash` heredocs, an *unescaped* `$VAR` / `${VAR}` is substituted by Docker at build time (used for build ARGs like `$DBT_VERSION`, `$TARGETARCH`, `$DELUGE_SRC_BRANCH`); a `\$VAR` / `\$(...)` is passed literally to the shell. Keep this convention when editing.
- **Pre-existing bug to fix while here:** `simulate_ci_image_build.sh` scrapes the Dockerfile with reversed `grep` arguments (`grep FILE PATTERN`), which prints a "No such file or directory" warning, yields empty output, and produces a malformed `docker buildx` command. Fix the argument order (`grep PATTERN FILE`) on both scrape lines.
- This is a Dockerfile/CI change with no unit-test surface. Verification is static (grep assertions) plus an optional heavy buildx run; the authoritative end-to-end check is CI on push.
- Do NOT bump `config.toml` `version`, and do NOT create git tags.

## File map

| File | Change | 
|---|---|
| `actions-support/ci-image/Dockerfile` | builder-stage ARG, branch clone + reset, delete version gate, echo version |
| `.github/workflows/release.yml` | `DELUGE_SRC_BRANCH` build-arg value `community` → `main` |
| `actions-support/simulate_ci_image_build.sh` | fix reversed `grep`; scrape `DELUGE_SRC_BRANCH` not `DELUGE_SRC_COMMIT` |

---

### Task 1: Track firmware `main` and force the toolchain version in the smoke build

This is one atomic change: the Dockerfile and both callers must move together (leaving a caller referencing `DELUGE_SRC_COMMIT` would break the sim build). Commit as a unit.

**Files:**
- Modify: `actions-support/ci-image/Dockerfile` (builder stage: ARG block ~50-53, `GIT_CHECKOUT` heredoc ~75-83, `SMOKE_BUILD` heredoc ~84-109)
- Modify: `.github/workflows/release.yml` (the `DELUGE_SRC_BRANCH=community` build-arg line)
- Modify: `actions-support/simulate_ci_image_build.sh` (the two `--build-arg $(grep ...)` scrape lines)

**Interfaces:**
- Consumes: `DBT_VERSION` (already an ARG in the builder stage, the toolchain version, e.g. `25`); `TARGETARCH` (already an ARG).
- Produces: a builder stage parameterised by `DELUGE_SRC_ORG` (default `synthstromaudible`) and `DELUGE_SRC_BRANCH` (default `main`); no `DELUGE_SRC_COMMIT`; `toolchain/REQUIRED_VERSION` set to `$DBT_VERSION` at smoke time.

- [ ] **Step 1: Capture the baseline (the pin + gate that will be removed)**

Run:
```bash
cd /home/kate/GitHub/dbt-toolchain
grep -n "DELUGE_SRC_COMMIT\|required_version\|Toolchain version mismatch\|DELUGE_SRC_BRANCH" \
  actions-support/ci-image/Dockerfile .github/workflows/release.yml actions-support/simulate_ci_image_build.sh
```
Expected (baseline): matches for `DELUGE_SRC_COMMIT` (Dockerfile ARG + `git checkout` + comment), `required_version` / `Toolchain version mismatch` (the gate), and `DELUGE_SRC_BRANCH=community` in `release.yml`. This is the state we are replacing.

- [ ] **Step 2: Update the builder-stage ARG block in `actions-support/ci-image/Dockerfile`**

Replace this block:

```dockerfile
ARG DBT_VERSION
# top-of-tree as of 2026-06-25
ARG DELUGE_SRC_ORG=synthstromaudible
ARG DELUGE_SRC_COMMIT=ae9f3996
ARG TARGETARCH
```

with:

```dockerfile
ARG DBT_VERSION
ARG DELUGE_SRC_ORG=synthstromaudible
ARG DELUGE_SRC_BRANCH=main
ARG TARGETARCH
```

- [ ] **Step 3: Rewrite the `GIT_CHECKOUT` heredoc to clone the branch tip**

Replace this block:

```dockerfile
RUN --mount=type=cache,target=/tmp/git_cache/ <<GIT_CHECKOUT bash
  set -ex
  git clone https://github.com/$DELUGE_SRC_ORG/DelugeFirmware.git /tmp/git_cache/DelugeFirmware || true
  cd /tmp/git_cache/DelugeFirmware/
  git fetch
  mkdir -p /build
  git checkout ${DELUGE_SRC_COMMIT}
  cp -r ./* ./.git/ /build/
GIT_CHECKOUT
```

with:

```dockerfile
RUN --mount=type=cache,target=/tmp/git_cache/ <<GIT_CHECKOUT bash
  set -ex
  git clone --branch $DELUGE_SRC_BRANCH https://github.com/$DELUGE_SRC_ORG/DelugeFirmware.git /tmp/git_cache/DelugeFirmware || true
  cd /tmp/git_cache/DelugeFirmware/
  # The cache mount can hold a warm clone; force the working tree to the current
  # branch tip instead of a stale cached checkout.
  git fetch origin $DELUGE_SRC_BRANCH
  git reset --hard origin/$DELUGE_SRC_BRANCH
  mkdir -p /build
  cp -r ./* ./.git/ /build/
GIT_CHECKOUT
```

- [ ] **Step 4: Rewrite the `SMOKE_BUILD` heredoc — delete the version gate, force the version**

Replace this block:

```dockerfile
RUN <<SMOKE_BUILD bash
  set -ex
  cd /build

  # Make sure we're smoke building against the correct toolchain version.
  #
  # If this test fails, edit DELUGE_SRC_COMMIT above to point to a commit that
  # edits toolchain/REQUIRED_VERSION in Deluge repo to point to the version
  # we're trying to build.
  required_version=\$(<toolchain/REQUIRED_VERSION)
  if [[ ! "${DBT_VERSION}" = "\${required_version}" ]]; then
      echo "Toolchain version mismatch";
      exit 1
  fi

  # We only actually build on amd64 because running the compiler under
  # emulation is extremely slow.
  case "$TARGETARCH" in
    amd64) ./dbt build ;;
    arm64) ./dbt configure ;;
    *)
      echo "Unsupported TARGETARCH" $TARGETARCH
      exit 1
      ;;
  esac
SMOKE_BUILD
```

with:

```dockerfile
RUN <<SMOKE_BUILD bash
  set -ex
  cd /build

  # Smoke-test firmware HEAD against exactly the toolchain we just built by
  # forcing REQUIRED_VERSION to this toolchain's version. This lets the smoke
  # build track the firmware branch tip without pinning a firmware commit.
  echo "${DBT_VERSION}" > toolchain/REQUIRED_VERSION

  # We only actually build on amd64 because running the compiler under
  # emulation is extremely slow.
  case "$TARGETARCH" in
    amd64) ./dbt build ;;
    arm64) ./dbt configure ;;
    *)
      echo "Unsupported TARGETARCH" $TARGETARCH
      exit 1
      ;;
  esac
SMOKE_BUILD
```

- [ ] **Step 5: Point `release.yml` at `main`**

In `.github/workflows/release.yml`, change the build-arg value:

```yaml
            DELUGE_SRC_BRANCH=community
```

to:

```yaml
            DELUGE_SRC_BRANCH=main
```

- [ ] **Step 6: Fix and retarget the scrape in `actions-support/simulate_ci_image_build.sh`**

Replace these two lines (note the reversed `grep` arguments in the originals):

```bash
  --build-arg $(grep ./ci-image/Dockerfile "^ARG DELUGE_SRC_ORG=" | sed 's_ARG __g') \
  --build-arg $(grep ./ci-image/Dockerfile "^ARG DELUGE_SRC_COMMIT=" | sed 's_ARG __g')  \
```

with (corrected `grep PATTERN FILE` order; second line now scrapes the branch):

```bash
  --build-arg $(grep "^ARG DELUGE_SRC_ORG=" ./ci-image/Dockerfile | sed 's_ARG __g') \
  --build-arg $(grep "^ARG DELUGE_SRC_BRANCH=" ./ci-image/Dockerfile | sed 's_ARG __g') \
```

- [ ] **Step 7: Static verification**

Run:
```bash
cd /home/kate/GitHub/dbt-toolchain
echo "--- no pin or gate should remain in the Dockerfile ---"
grep -n "DELUGE_SRC_COMMIT\|required_version\|Toolchain version mismatch" actions-support/ci-image/Dockerfile || echo "OK: pin and gate removed"
echo "--- new ARG + branch clone + version echo present ---"
grep -n "ARG DELUGE_SRC_BRANCH=main" actions-support/ci-image/Dockerfile
grep -n "git clone --branch \$DELUGE_SRC_BRANCH" actions-support/ci-image/Dockerfile
grep -n "git reset --hard origin/\$DELUGE_SRC_BRANCH" actions-support/ci-image/Dockerfile
grep -n 'echo "${DBT_VERSION}" > toolchain/REQUIRED_VERSION' actions-support/ci-image/Dockerfile
echo "--- no DELUGE_SRC_COMMIT anywhere (docs excluded) ---"
grep -rn "DELUGE_SRC_COMMIT" . --exclude-dir=.git --exclude-dir=docs --exclude-dir=.venv || echo "OK: no DELUGE_SRC_COMMIT references"
echo "--- release.yml points at main ---"
grep -n "DELUGE_SRC_BRANCH=main" .github/workflows/release.yml
echo "--- sim scrape now emits the branch build-arg cleanly (no warning, non-empty) ---"
( cd actions-support && grep "^ARG DELUGE_SRC_BRANCH=" ./ci-image/Dockerfile | sed 's_ARG __g' )
```
Expected: the first and fifth greps report "OK" (nothing removed remains); the ARG/clone/reset/echo greps each match exactly once; `release.yml` shows `DELUGE_SRC_BRANCH=main`; the final command prints `DELUGE_SRC_BRANCH=main` with **no** "No such file or directory" warning.

- [ ] **Step 8: Commit**

```bash
git add actions-support/ci-image/Dockerfile .github/workflows/release.yml actions-support/simulate_ci_image_build.sh
git commit -m "Track firmware main in CI-image smoke build instead of a pinned commit

Replace DELUGE_SRC_COMMIT with DELUGE_SRC_BRANCH=main, clone the branch tip
(git reset --hard to defeat the warm build-cache clone), drop the
REQUIRED_VERSION-vs-DBT_VERSION gate, and force toolchain/REQUIRED_VERSION to
the toolchain version being built. Point release.yml at main and fix the
reversed grep in simulate_ci_image_build.sh."
```

- [ ] **Step 9 (heavy; may be deferred to CI): end-to-end smoke build**

This actually builds the CI image: it clones firmware `main`, overwrites `REQUIRED_VERSION`, and runs `./dbt build` (amd64). It needs Docker + network and is slow, and it depends on a linux dist tarball existing in `dist/` (produced by `dbtbuilder` / `simulate_dist_build.sh`).

```bash
cd /home/kate/GitHub/dbt-toolchain
ls dist/dbt-toolchain-*-linux-x86_64.tar.gz  # must exist; if not, run ./actions-support/simulate_dist_build.sh first
./actions-support/simulate_ci_image_build.sh
```
Expected: buildx runs to completion; the `GIT_CHECKOUT` stage checks out firmware `main` HEAD; the `SMOKE_BUILD` stage writes the current toolchain version into `toolchain/REQUIRED_VERSION` and `./dbt build` completes without the old "Toolchain version mismatch" error and without any pinned commit.

**If `./dbt build` fails because firmware `main` needs source changes for this toolchain** (e.g. rustup wiring not yet merged): that is the intended loud failure of the echo-only design, not a plan defect. Record it and coordinate the firmware-side change; do not reintroduce a pinned commit to paper over it.

---

## Notes for the implementer

- **Why `git reset --hard origin/$DELUGE_SRC_BRANCH`:** the `--mount=type=cache` git cache can hold a clone from a previous build. `git clone` then no-ops (`|| true`) and the working tree would stay on the old tip; the explicit fetch + reset guarantees the branch tip is used whenever the RUN executes.
- **Docker layer-cache caveat:** CI's `build-push-action` configures no persistent layer cache, so this RUN re-executes each run and re-fetches. A warm *local* daemon cache can skip it — run `./actions-support/simulate_ci_image_build.sh` with `--no-cache` appended to the `docker buildx build` invocation if you need a guaranteed-fresh local rebuild. Adding a cache-bust ARG is deliberately out of scope (YAGNI).
- **Substitution sanity:** in the `SMOKE_BUILD` heredoc, `${DBT_VERSION}` and `$TARGETARCH` are Docker-substituted at build time; there are no remaining `\$`-escaped shell reads of `REQUIRED_VERSION` since the gate is gone. In `GIT_CHECKOUT`, `$DELUGE_SRC_ORG` and `$DELUGE_SRC_BRANCH` are Docker-substituted.
