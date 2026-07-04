# Design: Modular architecture for `dbtbuilder`

**Date:** 2026-07-04
**Status:** Approved (design); implementation plan to follow.

## Problem

`dbtbuilder.py` is a single 469-line script that fetches toolchain components from
`config.toml`, verifies checksums, extracts them, adds Python wheels, and packages
per-platform distribution archives. It works, but the monolith has accumulated problems
that block testing and can ship broken artifacts:

- **Silent failures.** `untar_archive` / `unzip_archive` / `add_python_lib` wrap their
  bodies in `try/except` and just `print(f"Error: {e}")` then continue. A failed
  extraction does not stop the build, so a broken toolchain can be packaged and released.
- **Untestable structure.** `sys.exit(-1)` is buried inside download/checksum helpers, so
  library logic makes process-level decisions. Everything is cwd-relative module globals
  (`ROOT_DIR = Path().resolve()`), and `main()` mixes config parsing, matrix construction,
  and 3-phase orchestration inline. There are no tests.
- **Smaller defects & smells.** Mutable default arguments on `Source.__init__`
  (`arch_map: dict = {}`); two HTTP mechanisms (`urllib` for checksums, `requests` for
  downloads) with an inline `import requests`; loose dict/str type-sniffing in
  `_get_source` and the `default`-expansion loop; empty `""""""` docstrings; scattered
  `# type: ignore`; mixed `print` / `rich_print`; dead commented code.

## Goals

- Restructure into an installable Python package with clear module boundaries.
- Make the pure logic (config parsing, URL formatting, matrix build, checksum, extraction
  filtering) unit-testable, and cover the I/O paths with local integration tests.
- Replace silent failures with a fail-fast error model.
- Keep the toolchain output byte-for-byte equivalent to today (same archives, same layout).

## Non-goals

- No change to the toolchain *contents* (package versions, sources, platform matrix).
- No new toolchain features; no semantic-versioning change to the release scheme.
- No unrelated refactoring beyond what serves the goals above.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Ambition | **Full package**: `pyproject.toml`, console entry point, test suite, CI/Docker updated. |
| Entry point | **Console script only.** Delete `dbtbuilder.py`; migrate all callers to `dbtbuilder` / `python -m dbtbuilder`. |
| Testing | **Unit + local integration** (no real network; stdlib `http.server` + tar/zip fixtures in `tmp_path`). |
| Dependencies | **pyproject-only** source of truth; CI uses `pip install .`; `prepare.sh` apt list trimmed. |

## Architecture

### Package layout (src-layout)

```
pyproject.toml            # hatchling build, deps, entry point, ruff + pytest config
src/dbtbuilder/
  __init__.py             # package version
  __main__.py             # `python -m dbtbuilder` -> cli.main()
  cli.py                  # argparse; wires config + paths + orchestrator; ONLY place that exits
  errors.py               # DbtBuilderError hierarchy
  model.py                # frozen dataclasses: Source, Package, BuildTarget, Config
  config.py               # load_config(path) -> Config  (parsing now inline in main())
  paths.py                # BuildPaths(root) -> dist/staging/cache  (injectable, no globals)
  http.py                 # single HTTP layer (requests): download_file + fetch_text
  checksum.py             # compute/verify; raises ChecksumMismatch
  download.py             # download_target(target, paths, http)
  extract.py              # extract_target: tar/zip/raw dispatch, include-filter, subdir-shift
  wheels.py               # add_python_lib
  package.py              # package_dist: archive + md5/sha256
  orchestrate.py          # build matrix; run download/extract/wheels/package phases
tests/
  fixtures/ …             # tiny tar/zip + checksum fixtures
  test_config.py test_model_url.py test_checksum.py
  test_extract.py test_download.py test_orchestrate.py
```

`dbtbuilder.py` and `version.py` are deleted; `release.yml` and `Dockerfile.sim` move to
`dbtbuilder` / `python -m dbtbuilder`.

### Domain model & config

- `Source` and `Package` become **frozen dataclasses**. The mutable-default-arg bug is
  fixed with `field(default_factory=dict)`.
- New `BuildTarget(package, platform, arch)` owns `format_url()`, the cache filename
  (`{platform}-{arch}-{basename}`), and the staging dest path — the per-target logic
  currently scattered across free functions.
- `Config` holds `version`, `platforms` (platform → arches), `sources`, `packages`.
- `config.py` absorbs the source construction and the package/`default`-expansion loop
  from today's `main()`, with **validation and clear error messages**: unknown source
  reference, missing `arch`, malformed `source` mapping, etc. (raising `ConfigError`).

### Error model (the core behavior fix)

- One exception hierarchy in `errors.py`:
  `DbtBuilderError` ← `ConfigError`, `DownloadError`, `ChecksumMismatch`, `ExtractError`.
- Helpers **raise**. The `sys.exit(-1)` calls and the `try/except: print(e)` swallowers in
  `untar_archive` / `unzip_archive` / `add_python_lib` are **removed**.
- `cli.main()` is the single catch site: it prints a rich error and returns a non-zero
  exit code.
- **Behavior change (intended):** the build now **fails fast**. A failed extraction,
  checksum, or download stops the run instead of printing and continuing to package a
  broken toolchain. This is the primary runtime difference from today.

### HTTP unification

Drop `urllib` entirely. Both downloads and checksum fetches go through `http.py` on
`requests` (already a dependency), with one timeout policy and the inline `import requests`
removed.

### CLI surface (argparse)

Default invocation (no args) reproduces today's full build. Flags:

- `--config PATH` (default `config.toml`)
- `--root PATH` (default cwd; feeds `BuildPaths`)
- `--platform {linux,darwin,win32}` and `--arch …` — build a subset of the matrix
- `--force` — re-extract even if the staging dir exists
- `--only download|extract|wheels|package` — run a single phase
- `-v/--verbose`
- `--version` — package version
- `--toolchain-version` — prints `config.toml`'s toolchain version (replaces `version.py`;
  CI's `python3 version.py` step is updated accordingly)

### Paths

`BuildPaths` is a dataclass built from a root directory (default cwd, overridable via
`--root`), exposing `dist`, `staging`, and `cache`. It is passed explicitly to the
functions that need it instead of the current module-level globals, which is what makes
`tmp_path`-based integration tests possible.

## Testing

- **Unit (pure logic):** config parse + validation; `format_url` across the full
  platform×arch matrix; checksum comparison; matrix construction; `shift_subdir_up`;
  include-list filtering.
- **Integration (`tmp_path`, no network):** real tar/zip fixtures exercised through
  `extract_target`; downloads served by a stdlib `http.server` bound to localhost so
  `download_target` runs its real code path including checksum verification.
- Dev dependency is just `pytest` (`[project.optional-dependencies] dev = ["pytest"]`).

## Packaging & CI

- **`pyproject.toml`:** hatchling backend, `requires-python >= 3.12`, runtime deps
  `[requests, rich, tqdm]`, `dev = [pytest]`, `console_scripts`
  `dbtbuilder = "dbtbuilder.cli:main"`, plus ruff and pytest configuration.
- **`.github/workflows/release.yml`:** replace `pip install -r requirements.txt` with
  `pip install .` (and `.[dev]` where tests run); add a `pytest` step; run the build via
  `dbtbuilder`; swap the `python3 version.py` step for `dbtbuilder --toolchain-version`.
- **`actions-support/dist-build/Dockerfile.sim`** and `simulate_dist_build.sh`: entry
  point → `dbtbuilder`.
- **`actions-support/dist-build/prepare.sh`:** keep `curl`, `perl`, `zip`; drop the now
  redundant `python3-rich` / `python3-tqdm` / `python3-requests` apt packages.
- Delete `requirements.txt` (superseded by pyproject).

## Sequencing (keep CI green throughout)

1. Add `pyproject.toml` and the package skeleton; move existing code into modules
   **behaviorally unchanged** behind the entry point.
2. Refactor to dataclasses / `model` + `config` + `paths`.
3. Apply the error model and HTTP unification.
4. Add the test suite.
5. In one commit, flip `release.yml` / `Dockerfile.sim` / `prepare.sh`, delete
   `dbtbuilder.py`, `version.py`, and `requirements.txt`.

## Risks

- **Fail-fast is a behavior change.** Runs that previously limped past a bad
  extraction/checksum will now stop. This is intended, but the first CI run after the
  change may surface a latent failure that was being silently ignored.
- **Byte-for-byte output.** The dist archives and their internal layout must match today's
  output; the refactor preserves the archive names, member `arcname`s, compression
  settings, and hash-file format. A build-and-diff against a pre-refactor run is the
  acceptance check.
- **Windows executable bit / `set-executable` handling** must be preserved exactly through
  the extract/copy path.
