# Rust (rustup) in dbt-toolchain — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `rustup-init` bootstrapper in every dbt-toolchain toolpack so DelugeFirmware can obtain its pinned nightly Rust toolchain.

**Architecture:** Add a `rust` source and a `rustup-init` package to `config.toml`, reusing the existing raw-binary + `set-executable` code path used by `clang-format`. Two small `dbtbuilder.py` fixes are also required (discovered during execution): unique-per-platform cache filenames (rustup-init's URL basename is identical across platforms and collides), and applying the executable bit to the *staged* file rather than the cache copy (so the shipped binary is actually runnable). A smoke-test assertion in the CI-image Dockerfile confirms the binary ships and runs. The heavyweight nightly toolchain is fetched on first build by rustup (into the firmware's toolchain tree), never bundled here.

**Tech Stack:** Python 3.12 (`dbtbuilder.py`, stdlib `tomllib`), TOML config, Docker/buildx smoke test, rustup-init binaries from `static.rust-lang.org`.

## Global Constraints

- Pin rustup to version **`1.28.2`** (stable checksum, dbt-style). If a newer rustup release exists at implementation time, use it and adjust the version string everywhere it appears.
- **Two `dbtbuilder.py` fixes are required** (found during execution, not anticipated in the spec): (1) cache filenames must be unique per platform-arch — `rustup-init`'s URL basename is identical across all non-Windows platforms and collides in `cache/`; (2) the executable bit must be applied to the staged file (which gets packaged), not the cache copy, or the shipped binary is not runnable. The second fix also corrects `clang-format`, which had the same latent issue.
- rustup-init archive URL shape: `https://static.rust-lang.org/rustup/archive/{version}/{arch}-{platform}/{name}{ext}`, checksum at `{url}.sha256` (sha256, body `<hash> *./rustup-init`).
- Version rules (from README): whole-number versions only; bump the top-level `version` in `config.toml`; edit `RELEASE.md`. **Do not create or push git tags** — tagging is a manual maintainer release step, out of scope for this plan.
- Current `config.toml` `version` is `24`; this change bumps it to `25`.
- Ship the bootstrapper only. No toolchain-selection logic lives in this repo; DelugeFirmware's `rust-toolchain.toml` + rustup own that (see spec §3).

---

### Task 1: Add the `rust` source and `rustup-init` package to `config.toml`

**Files:**
- Modify: `config.toml` (add `[sources.rust]`, add `rustup-init` to `[packages]`, bump `version`)
- Modify: `dbtbuilder.py` (unique-per-platform cache filenames; chmod the staged executable) — see Steps 3a/3b

**Interfaces:**
- Consumes: the existing `Source` / `Package` / `download_package` API in `dbtbuilder.py`.
- Produces: a `rustup-init` package resolving to these URLs (all verified HTTP 200 with `.sha256` siblings):
  - `linux-x86_64`  → `.../archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init`
  - `linux-arm64`   → `.../archive/1.28.2/aarch64-unknown-linux-gnu/rustup-init`
  - `darwin-x86_64` → `.../archive/1.28.2/x86_64-apple-darwin/rustup-init`
  - `darwin-arm64`  → `.../archive/1.28.2/aarch64-apple-darwin/rustup-init`
  - `win32-x86_64`  → `.../archive/1.28.2/x86_64-pc-windows-msvc/rustup-init.exe`
  - After build, staged at `staging/{platform}-{arch}/rustup-init/rustup-init[.exe]`.

- [ ] **Step 1: Write the failing check**

Save nothing to disk — run this verification snippet from the repo root. It reuses the builder's own classes to resolve and download-verify (checksum) the `rustup-init` package for every platform-arch:

```bash
python3 - <<'EOF'
import tomllib
import dbtbuilder as b

cfg = tomllib.load(open("config.toml", "rb"))
sources = {
    n: b.Source(n, d["url"], d.get("checksum_type") or "sha256",
                d.get("checksum_url"), d.get("arch") or {},
                d.get("ext") or {}, d.get("platform") or {})
    for n, d in cfg["sources"].items()
}
details = cfg["packages"]["rustup-init"]
pairs = [(p, a) for p, pd in cfg["platforms"].items() for a in pd["arch"]]
for plat, arch in pairs:
    pkg = b.Package("rustup-init", plat, details, sources)
    print(plat, arch, "->", pkg.format_url(arch))
    b.download_package(pkg, plat, arch)
print("all rustup-init downloads verified")
EOF
```

- [ ] **Step 2: Run it to verify it fails**

Run the snippet above.
Expected: `KeyError: 'rustup-init'` (the package does not exist in `config.toml` yet).

- [ ] **Step 3: Add the source and package to `config.toml`**

Append this source block to the `[sources]` section (place it after the `clang-tools-static-binaries` source, before `[packages]`):

```toml
[sources.rust]
url = "https://static.rust-lang.org/rustup/archive/{version}/{arch}-{platform}/{name}{ext}"
checksum_url = "{url}.sha256"
ext.default = ""
ext.win32 = ".exe"
arch.arm64 = "aarch64"
platform.linux = "unknown-linux-gnu"
platform.darwin = "apple-darwin"
platform.win32 = "pc-windows-msvc"
```

Add this line to the `[packages]` section (e.g. after the `clang-format` line):

```toml
# rustup bootstrapper; DBT runs this to install DelugeFirmware's pinned nightly.
# See docs/superpowers/specs/2026-07-04-rust-rustup-toolchain-design.md
rustup-init = { version = "1.28.2", source = "rust", set-executable = true }
```

Change the first line of `config.toml` from:

```toml
version = 24
```

to:

```toml
version = 25
```

- [ ] **Step 3a: Fix cache-filename collision in `dbtbuilder.py`**

`rustup-init`'s URL basename is `rustup-init` for every non-Windows platform, so all variants collide at `cache/rustup-init` (wrong checksum / wrong staged binary). Make the cache filename unique. Both `download_package` (lines ~109-110) and `extract_package` (lines ~138-139) contain this identical pair — replace **both** occurrences:

```python
    filename = os.path.basename(url)
    filepath = CACHE_PATH / filename
```

with:

```python
    filename = f"{platform}-{arch}-{os.path.basename(url)}"
    filepath = CACHE_PATH / filename
```

- [ ] **Step 3b: Make `set-executable` apply to the staged file in `dbtbuilder.py`**

`download_package` chmods the cache copy, but `extract_package` uses `shutil.copyfile` (no mode) to produce the staged file that actually gets packaged, so the shipped binary is `0644` (not runnable). In `extract_package`'s raw-binary branch, after the `shutil.copyfile(filepath, dest_path)` line, add the chmod:

```python
        shutil.copyfile(filepath, dest_path)
        # copyfile drops permissions; re-apply the executable bit to the staged
        # file (the one that gets packaged) when the package asks for it.
        if package.details.get("set-executable", False):
            os.chmod(dest_path, 0o755)
```

- [ ] **Step 4: Run the check to verify it passes**

Run the same snippet from Step 1 again.
Expected output: the five resolved URLs printed, each followed by a `Found .../checking SHA256...VALID` (or a download + validation) line, ending with `all rustup-init downloads verified`. Non-zero exit or an `Error!` line means a URL or checksum is wrong — fix before continuing.

- [ ] **Step 5: Commit**

```bash
git add config.toml dbtbuilder.py
git commit -m "Add rustup-init package (Rust toolchain bootstrapper)"
```

---

### Task 2: Add the rustup-init smoke-test assertion to the CI-image build

**Files:**
- Modify: `actions-support/ci-image/Dockerfile` (add an assertion inside the `toolchain-unpacker` stage's `LOAD_TOOLCHAIN` heredoc)

**Interfaces:**
- Consumes: the `staging`/tarball layout produced by Task 1 — `linux-x86_64/rustup-init/rustup-init` inside the unpacked toolchain, executable.
- Produces: a build-time failure if `rustup-init` is missing or non-runnable.

- [ ] **Step 1: Add the assertion to the Dockerfile**

In `actions-support/ci-image/Dockerfile`, inside the `LOAD_TOOLCHAIN` heredoc, the working directory is `/dbt/toolchain/v${DBT_VERSION}` (set by the `cd` earlier in the heredoc). Find these lines near the end of that heredoc:

```bash
  # kinda stupid hack: move linux-x86_64 to linux-amd64 so we can do a COPY
  # --from below using the Docker TARGETARCH. We then move it back to the right position
  mv /dbt/toolchain/v\${DBT_VERSION}/linux-x86_64/ /dbt/toolchain/v\${DBT_VERSION}/linux-amd64
```

Insert these three lines immediately **before** the `# kinda stupid hack` comment:

```bash
  # Smoke-check that the Rust bootstrapper shipped and is runnable
  test -x linux-x86_64/rustup-init/rustup-init
  ./linux-x86_64/rustup-init/rustup-init --version
```

- [ ] **Step 2: Verify the assertion logic against a real artifact**

The assertion runs inside the full CI-image build, which is heavy and (until the DelugeFirmware follow-up bumps `toolchain/REQUIRED_VERSION` and wires up rustup) will not complete its later `./dbt build` stage. So verify the assertion *logic* directly against a built tarball instead.

Build the linux tarball, then extract and run the same two commands the Dockerfile now runs:

```bash
# Produces dist/ + staging/ for all platform-archs (downloads all packages; slow).
./actions-support/simulate_dist_build.sh

# Reproduce the Dockerfile assertion against the freshly built linux-x86_64 toolpack.
rm -rf /tmp/rustup-smoke && mkdir -p /tmp/rustup-smoke
tar xf dist/dbt-toolchain-25-linux-x86_64.tar.gz -C /tmp/rustup-smoke
test -x /tmp/rustup-smoke/linux-x86_64/rustup-init/rustup-init
/tmp/rustup-smoke/linux-x86_64/rustup-init/rustup-init --version
```

Expected: `test -x` exits 0 and `rustup-init --version` prints something like `rustup-init 1.28.2 (...)`. If `simulate_dist_build.sh` is too heavy to run locally, this is acceptable to defer to CI — but confirm the `dist/` tarball exists and contains `linux-x86_64/rustup-init/rustup-init` before relying on CI.

- [ ] **Step 3: Commit**

```bash
git add actions-support/ci-image/Dockerfile
git commit -m "Smoke-test that rustup-init ships and runs"
```

---

### Task 3: Document the package, the integration contract, and the release note

**Files:**
- Modify: `README.md` (add a **Rust** subsection under "Toolchain inclusions" → "Details")
- Modify: `RELEASE.md` (replace with the v25 changelog)

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: the published integration contract DelugeFirmware's DBT scripts must honor.

- [ ] **Step 1: Add the Rust subsection to `README.md`**

Under the "### Details:" heading in `README.md`, add this subsection after the existing `#### Python` block:

```markdown
#### Rust (rustup)

The toolchain ships `rustup-init`, the official Rust toolchain bootstrapper. It
is a single binary at `<toolchain>/rustup-init/rustup-init[.exe]`. The actual
Rust nightly toolchain is **not** bundled — it is installed on first build by
rustup, driven by DelugeFirmware's `rust-toolchain.toml` (nightly + `rust-src`,
`clippy`, `rustfmt`, `llvm-tools-preview`, and the `armv7a-none-eabihf` /
`i686-unknown-linux-gnu` targets). This means the first Rust build requires
network access.

DBT is responsible for bootstrapping rustup so it stays self-contained inside
the portable toolchain tree (not the developer's `~/.rustup` / `~/.cargo`):

    # Point rustup/cargo state inside the toolchain tree
    RUSTUP_HOME = <toolchain>/rust/rustup
    CARGO_HOME  = <toolchain>/rust/cargo

    # One-time bootstrap (first build)
    rustup-init -y --no-modify-path --profile minimal --default-toolchain none

    # Every build: prepend $CARGO_HOME/bin to PATH

`--default-toolchain none` makes DelugeFirmware's `rust-toolchain.toml` the
single source of truth; the first `cargo`/`rustc` call from the firmware tree
auto-installs the pinned toolchain, components, and targets.
```

- [ ] **Step 2: Update `RELEASE.md`**

Replace the entire contents of `RELEASE.md` with:

```markdown
# Changes from v24

- Add `rustup-init` (Rust toolchain bootstrapper) to the toolpack
```

- [ ] **Step 3: Verify the docs render and are internally consistent**

Run:

```bash
grep -n "rustup-init" README.md RELEASE.md config.toml
```

Expected: matches in all three files, all referring to the `rustup-init` package name (no stray `rustup` mismatches), and `RELEASE.md` reads `Changes from v24`.

- [ ] **Step 4: Commit**

```bash
git add README.md RELEASE.md
git commit -m "Document rustup-init package and integration contract"
```

---

## Notes for the implementer

- **Reproducibility / floating nightly:** DelugeFirmware pins `channel = "nightly"` (floating), so the first build of a given day gets whatever nightly is current. That is the firmware repo's decision, not this repo's. Nothing to do here; documented in the spec §4.
- **Windows MSVC linker:** the `x86_64-pc-windows-msvc` host toolchain expects MSVC `link.exe`. This may surface in the DelugeFirmware follow-up, not in this packaging work. Out of scope.
- **DelugeFirmware follow-up (separate):** implementing the §3 contract in DBT's build scripts, and bumping `toolchain/REQUIRED_VERSION` to `25` so the full CI-image `./dbt build` smoke stage passes end-to-end.
```
