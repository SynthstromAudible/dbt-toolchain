# Rust (rustup) in dbt-toolchain — Design

**Date:** 2026-07-04
**Status:** Approved design, pending implementation plan

## Problem

DelugeFirmware now builds Rust code and requires a **nightly** toolchain. Its
`crates/rust-toolchain.toml` and `src/bsp/rust/rust-toolchain.toml` pin:

- `channel = "nightly"` — required for `-Z build-std` (the bare-metal
  `armv7a-none-eabihf` target has no prebuilt `std`/`core`)
- components: `rust-src`, `clippy`, `rustfmt`, `llvm-tools-preview`
- targets: `armv7a-none-eabihf` (firmware link, via a CMake
  `add_custom_command` that shells out to
  `cargo build --target armv7a-none-eabihf`), `i686-unknown-linux-gnu`
  (conformance staticlib), plus the host target (unit/proptest/fuzz tests)

dbt-toolchain must make a Rust toolchain available to that build the same way it
already provides cmake, ninja, arm-none-eabi-gcc, python, clang-format, etc.

## Decisions

Two decisions were made during brainstorming and drive this design:

1. **Distribution model: ship `rustup-init`, not a pre-bundled toolchain.**
   First-build network access is acceptable. We ship the small `rustup-init`
   bootstrapper; rustup then reads DelugeFirmware's `rust-toolchain.toml` and
   installs the pinned nightly + components + targets on first use. This is the
   idiomatic path, respects `rust-toolchain.toml` natively, and gets
   component/target/update handling for free. Trade-off: the first build needs
   the network, and a floating `nightly` channel is non-reproducible unless the
   firmware repo pins a date (see Known Wrinkles).

2. **Scope: packaging + integration contract.** This spec covers adding
   `rustup-init` to `config.toml` *and* documents the exact contract the DBT
   (DelugeFirmware) side must implement (env vars, bootstrap invocation, PATH).
   The DelugeFirmware-side code changes are a separate follow-up; the contract
   is defined here so both sides agree.

Alternatives considered and rejected: bundling a full offline standalone
toolchain (large; must pin and track a nightly date; must shim the floating
`nightly` channel) and a hybrid pre-warmed `RUSTUP_HOME` (offline + rustup
semantics but the most complex to build and maintain). Neither was justified
once first-build network access was accepted.

## Design

### 1. `config.toml` — new source + package

Add a `rust` source, structurally a twin of the existing
`python-build-standalone` source (platform/arch maps). rustup-init archive URLs
combine arch + platform into a Rust host triple, which the existing
`{platform}` / `{arch}` substitution model expresses directly:

```toml
[sources.rust]
url = "https://static.rust-lang.org/rustup/archive/{version}/{arch}-{platform}/{name}{ext}"
checksum_url = "{url}.sha256"   # checksum_type defaults to sha256
ext.default = ""
ext.win32 = ".exe"
arch.arm64 = "aarch64"          # x86_64 passes through unchanged
platform.linux = "unknown-linux-gnu"
platform.darwin = "apple-darwin"
platform.win32 = "pc-windows-msvc"
```

Add the package to `[packages]`:

```toml
rustup-init = { version = "1.28.2", source = "rust", set-executable = true }
```

Resolved URLs (all five triples verified to return HTTP 200 with a `.sha256`
sibling at rustup 1.27.1, and the `1.28.2` pin verified for linux-x86_64; each
`.sha256` body is `<hash> *./rustup-init`, handled by the existing
`checksum_remote` via `.split()[0]`):

| dbt platform-arch | Rust host triple           | filename         |
|-------------------|----------------------------|------------------|
| linux-x86_64      | x86_64-unknown-linux-gnu   | rustup-init      |
| linux-arm64       | aarch64-unknown-linux-gnu  | rustup-init      |
| darwin-x86_64     | x86_64-apple-darwin        | rustup-init      |
| darwin-arm64      | aarch64-apple-darwin       | rustup-init      |
| win32-x86_64      | x86_64-pc-windows-msvc     | rustup-init.exe  |

Notes:

- The package key is **`rustup-init`** (not `rustup`) so `{name}` resolves to
  the real upstream filename and the binary is never mis-renamed.
  `rustup-init` is the installer/bootstrapper — distinct from the `rustup`
  multiplexer it later lays down. The raw-binary branch of `extract_package`
  places it at `staging/{platform}-{arch}/rustup-init/rustup-init[.exe]`.
- `set-executable = true` reuses the exact code path `clang-format` already
  uses (raw binary → `chmod` → copy into staging). No `.include` file is
  needed because this is not an archive.
- `version` is a pin, giving a stable checksum in dbt's versioned style.
  `1.28.2` is the concrete value in this spec; the implementer confirms the
  current rustup release at build time and, per the repo's release rules,
  bumps the top-level `version` in `config.toml` when adding this package.

### 2. Bundled artifact

Each toolpack gains exactly one file:
`staging/{platform}-{arch}/rustup-init/rustup-init[.exe]` (~15–20 MB). The
heavyweight nightly toolchain (rustc, std, rust-src — hundreds of MB) is fetched
on first build into the firmware's toolchain tree (see §3), never into the
distributed toolpack.

### 3. Integration contract (implemented in DelugeFirmware, documented here)

dbt-toolchain ships no toolchain logic. It publishes this contract for the DBT
side to honor. The contract keeps Rust self-contained inside the portable
toolchain tree and out of the developer's `~/.rustup` / `~/.cargo`:

```
Environment (point rustup/cargo state inside the toolchain tree):
  RUSTUP_HOME = <toolchain>/rust/rustup     # installed toolchains
  CARGO_HOME  = <toolchain>/rust/cargo      # shims + registry cache

One-time bootstrap (first build):
  rustup-init -y --no-modify-path --profile minimal --default-toolchain none

Every build:
  prepend  $CARGO_HOME/bin  to PATH
```

`--default-toolchain none` makes DelugeFirmware's `rust-toolchain.toml` the
single source of truth. The first `cargo`/`rustc` invocation from a directory
under that file auto-installs the pinned nightly plus
`rust-src`/`clippy`/`rustfmt`/`llvm-tools-preview` and the
`armv7a-none-eabihf` / `i686-unknown-linux-gnu` targets. rustup + the firmware
repo own all toolchain selection; dbt-toolchain only provides the bootstrapper
on `PATH`-reachable disk.

### 4. Known wrinkles (documented, not solved here)

- **Reproducibility.** `channel = "nightly"` is floating, so the
  first-build-of-the-day pulls whatever nightly is current. That is the
  firmware repo's decision, not dbt-toolchain's. If DelugeFirmware wants
  deterministic builds it should pin `nightly-YYYY-MM-DD` in its
  `rust-toolchain.toml`. Out of scope for this spec; noted for the follow-up.
- **Windows.** The `x86_64-pc-windows-msvc` host toolchain expects MSVC
  `link.exe`. The `armv7a-none-eabihf` firmware cross-link uses lld/gcc, so
  this may not bite the firmware build, but host-side Rust tests could.
  Flagged as an open risk for the DBT-side follow-up; a
  `x86_64-pc-windows-gnu` host is a possible fallback.

### 5. Testing

- Extend the existing docker smoke test to assert the built toolpack contains
  `rustup-init` and that `rustup-init --version` runs successfully.

### 6. Documentation

- Add a **Rust** subsection under "Toolchain inclusions" in `README.md`
  documenting the `rustup-init` package and the integration contract in §3.

## Files touched (dbt-toolchain)

- `config.toml` — add `[sources.rust]`, add the `rustup-init` package, bump
  top-level `version`.
- `dbtbuilder.py` — two fixes surfaced during implementation (see below).
- `README.md` — add the Rust subsection.
- docker smoke test (under `actions-support/` / `.github/`) — add the
  `rustup-init` presence + `--version` assertion.

Two `dbtbuilder.py` fixes proved necessary (the raw-binary + `set-executable`
path did *not* fully handle this package shape, contrary to the original
assumption):

1. **Unique cache filenames.** `rustup-init`'s URL basename is `rustup-init`
   for every non-Windows platform (the host triple lives in the URL directory,
   not the filename), so all variants collided at `cache/rustup-init`. Cache
   filenames are now prefixed with `{platform}-{arch}-`.
2. **Executable bit on the staged file.** `set-executable` chmod'd the cache
   copy, but `extract_package` uses `shutil.copyfile` (data only) to produce the
   staged file that actually gets packaged, so the shipped binary was `0644`.
   The chmod is now applied to the staged file. This also corrects
   `clang-format`, which had the same latent issue.

## Out of scope (separate DelugeFirmware follow-up)

- Implementing the §3 contract in the DBT build scripts (env vars, bootstrap
  invocation, PATH wiring).
- Any decision to pin the nightly date in `rust-toolchain.toml`.
- Resolving the Windows MSVC-linker question.
