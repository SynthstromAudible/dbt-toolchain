# dbtbuilder Modular Architecture — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the 469-line monolithic `dbtbuilder.py` into an installable, unit-tested `dbtbuilder` Python package with clear module boundaries and a fail-fast error model, while producing byte-for-byte identical toolchain archives.

**Architecture:** A `src/`-layout package (`src/dbtbuilder/`) split by responsibility — `model` (frozen dataclasses), `config` (parse `config.toml`), `paths` (injectable directories), `http`/`checksum`/`download`/`extract`/`wheels`/`package` (I/O units), `orchestrate` (matrix + phases), and `cli` (argparse, the only place that exits). Errors raise a `DbtBuilderError` hierarchy instead of printing-and-continuing or calling `sys.exit`. The package is built by hatchling and exposes a `dbtbuilder` console script plus `python -m dbtbuilder`. CI, the Docker sim, and `prepare.sh` migrate off the deleted `dbtbuilder.py`/`version.py`/`requirements.txt`.

**Tech Stack:** Python 3.12 (stdlib `tomllib`, `tarfile`, `zipfile`, `hashlib`, `argparse`), `requests` for all HTTP, `rich` + `tqdm` for output, `pytest` for tests, hatchling build backend.

## Global Constraints

- **`requires-python >= 3.12`** (uses `tomllib` and `hashlib.file_digest`, both 3.11+; repo targets 3.12).
- **Runtime dependencies, pinned exactly:** `requests==2.32.3`, `rich==13.9.4`, `tqdm==4.67.1`. Dev: `pytest>=8`.
- **Console-script only.** The package is invoked as `dbtbuilder` or `python -m dbtbuilder`. `dbtbuilder.py` is deleted at the end; all callers migrate in the same commit.
- **pyproject-only dependencies.** `requirements.txt` is deleted; CI uses `pip install .` / `.[dev]`.
- **Fail-fast error model.** Library functions raise `DbtBuilderError` subclasses. No `sys.exit` and no `try/except: print(e)` outside `cli.main()`, which is the single catch site and returns the process exit code.
- **Byte-for-byte output parity is the acceptance bar.** Preserve archive names (`dbt-toolchain-{version}-{platform}-{arch}.{tar.gz|zip}`), member `arcname`s (relative to the `staging/` dir, so prefixed `{platform}-{arch}/…`), `compresslevel=6` for tar, `ZIP_DEFLATED` for zip, the `VERSION` file content (`f"{version}\n"`), and hash sidecar files (`{archive}.md5` / `{archive}.sha256`, containing only the hex digest, no newline).
- **`set-executable` must apply to the *staged* file** (the one packaged), chmod `0o755` after `shutil.copyfile` drops the bit.
- **Do NOT bump `config.toml` `version`** (currently `25`). This change alters no toolchain content.
- **Do NOT create or push git tags** — tagging is a manual maintainer release step (README rules), out of scope.
- Every task ends by running `pytest` (green) and committing. Run tests with `python -m pytest`.

## File map

| File | Responsibility | Task |
|---|---|---|
| `pyproject.toml` | build backend, deps, entry point, ruff/pytest config | 1 |
| `src/dbtbuilder/__init__.py` | package version | 1 |
| `src/dbtbuilder/errors.py` | `DbtBuilderError` hierarchy | 1 |
| `src/dbtbuilder/model.py` | `Source`, `Package`, `BuildTarget`, `Config` | 2 |
| `src/dbtbuilder/config.py` | `load_config` / `parse_config` | 3 |
| `src/dbtbuilder/paths.py` | `BuildPaths` | 4 |
| `src/dbtbuilder/http.py` | `download_file`, `fetch_text` | 5 |
| `src/dbtbuilder/checksum.py` | `file_digest`, `verify_remote` | 5 |
| `src/dbtbuilder/download.py` | `download_target` | 6 |
| `src/dbtbuilder/extract.py` | `extract_target`, `untar_archive`, `unzip_archive`, `shift_subdir_up` | 7 |
| `src/dbtbuilder/wheels.py` | `add_python_lib`, `get_sysname_arch` | 8 |
| `src/dbtbuilder/package.py` | `package_dist`, `create_tar_gz`, `create_zip` | 9 |
| `src/dbtbuilder/orchestrate.py` | `run_build` | 10 |
| `src/dbtbuilder/cli.py` + `__main__.py` | argparse entry point | 11 |
| CI / Docker / prepare.sh; delete monolith | migration | 12 |

---

### Task 1: Project skeleton, packaging, and error hierarchy

**Files:**
- Create: `pyproject.toml`
- Create: `src/dbtbuilder/__init__.py`
- Create: `src/dbtbuilder/errors.py`
- Test: `tests/test_errors.py`

**Interfaces:**
- Produces: package `dbtbuilder` importable after `pip install -e .[dev]`; `dbtbuilder.__version__: str`; exception classes `DbtBuilderError`, `ConfigError`, `DownloadError`, `ChecksumMismatch`, `ExtractError` (the last four all subclass `DbtBuilderError`).

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "dbtbuilder"
version = "1.0.0"
description = "Build tool for the Deluge Build Tool (DBT) toolchain toolpacks."
requires-python = ">=3.12"
dependencies = [
    "requests==2.32.3",
    "rich==13.9.4",
    "tqdm==4.67.1",
]

[project.optional-dependencies]
dev = ["pytest>=8"]

[project.scripts]
dbtbuilder = "dbtbuilder.cli:main"

[tool.hatch.build.targets.wheel]
packages = ["src/dbtbuilder"]

[tool.ruff]
line-length = 100

[tool.pytest.ini_options]
testpaths = ["tests"]
```

- [ ] **Step 2: Create `src/dbtbuilder/__init__.py`**

Silence tqdm's experimental-rich warning once, at package import (the monolith did this globally; every I/O module imports `tqdm.rich`).

```python
"""dbtbuilder — fetch, verify, and package the DBT toolchain."""

import warnings

from tqdm import TqdmExperimentalWarning

warnings.filterwarnings("ignore", category=TqdmExperimentalWarning)

__version__ = "1.0.0"
```

- [ ] **Step 3: Create `src/dbtbuilder/errors.py`**

```python
"""Exception hierarchy for dbtbuilder.

Library code raises these; only cli.main() catches them and turns them into a
process exit code. Nothing prints-and-continues.
"""


class DbtBuilderError(Exception):
    """Base class for every dbtbuilder failure."""


class ConfigError(DbtBuilderError):
    """config.toml is missing keys, malformed, or references unknown names."""


class DownloadError(DbtBuilderError):
    """An HTTP fetch or file download failed."""


class ChecksumMismatch(DbtBuilderError):
    """A downloaded file's digest did not match its published checksum."""


class ExtractError(DbtBuilderError):
    """An archive could not be extracted."""
```

- [ ] **Step 4: Write the failing test — `tests/test_errors.py`**

```python
import pytest

from dbtbuilder import __version__
from dbtbuilder.errors import (
    ChecksumMismatch,
    ConfigError,
    DbtBuilderError,
    DownloadError,
    ExtractError,
)


def test_version_is_a_string():
    assert isinstance(__version__, str)


@pytest.mark.parametrize(
    "exc", [ConfigError, DownloadError, ChecksumMismatch, ExtractError]
)
def test_all_errors_subclass_base(exc):
    assert issubclass(exc, DbtBuilderError)
    with pytest.raises(DbtBuilderError):
        raise exc("boom")
```

- [ ] **Step 5: Install the package and run the test to verify it passes**

Run:
```bash
pip install -e ".[dev]"
python -m pytest tests/test_errors.py -v
```
Expected: editable install succeeds; both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add pyproject.toml src/dbtbuilder/__init__.py src/dbtbuilder/errors.py tests/test_errors.py
git commit -m "Add dbtbuilder package skeleton and error hierarchy"
```

---

### Task 2: Domain model (`Source`, `Package`, `BuildTarget`, `Config`)

**Files:**
- Create: `src/dbtbuilder/model.py`
- Test: `tests/test_model_url.py`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `Source(name, url, checksum_type, checksum_url, arch_map={}, ext_map={}, platform_map={})` — frozen dataclass; `checksum_url: str | None`; the three `*_map` fields default via `field(default_factory=dict)`.
  - `Package(name, platform, details, source)` — frozen dataclass; `details: dict[str, Any]`; `source: Source` (already resolved by `config`).
  - `BuildTarget(package, arch)` — frozen dataclass; `.platform -> str`; `.format_url() -> str`; `.cache_filename() -> str` (returns `f"{platform}-{arch}-{basename(url)}"`).
  - `Config(version, platforms, sources, packages)` — frozen; `platforms: dict[str, list[str]]`; `.platform_arch_pairs() -> list[tuple[str, str]]`; `.build_targets() -> list[BuildTarget]` (one per package×matching-platform×arch).

- [ ] **Step 1: Write the failing test — `tests/test_model_url.py`**

```python
from dbtbuilder.model import BuildTarget, Config, Package, Source


def _xpack_source():
    return Source(
        name="xpack",
        url="https://h/{name}-{version}-{platform}-{arch}.{ext}",
        checksum_type="sha256",
        checksum_url="{url}.sha",
        arch_map={"x86_64": "x64"},
        ext_map={"default": "tar.gz", "win32": "zip"},
    )


def test_format_url_applies_arch_ext_and_details():
    src = _xpack_source()
    pkg = Package("cmake", "linux", {"version": "3.31.9-1", "source": "xpack"}, src)
    target = BuildTarget(pkg, "x86_64")
    assert target.format_url() == "https://h/cmake-3.31.9-1-linux-x64.tar.gz"


def test_cache_filename_is_unique_per_platform_arch():
    src = _xpack_source()
    pkg = Package("cmake", "win32", {"version": "1", "source": "xpack"}, src)
    target = BuildTarget(pkg, "x86_64")
    # win32 -> ext 'zip', arch x86_64 -> 'x64'
    assert target.format_url().endswith("cmake-1-win32-x64.zip")
    assert target.cache_filename() == "win32-x86_64-cmake-1-win32-x64.zip"


def test_build_targets_pairs_packages_with_matching_platform():
    src = _xpack_source()
    packages = [
        Package("a", "linux", {"source": "xpack", "version": "1"}, src),
        Package("a", "win32", {"source": "xpack", "version": "1"}, src),
    ]
    cfg = Config(
        version=25,
        platforms={"linux": ["x86_64", "arm64"], "win32": ["x86_64"]},
        sources={"xpack": src},
        packages=packages,
    )
    got = {(t.platform, t.arch) for t in cfg.build_targets()}
    assert got == {("linux", "x86_64"), ("linux", "arm64"), ("win32", "x86_64")}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_model_url.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.model'`.

- [ ] **Step 3: Create `src/dbtbuilder/model.py`**

```python
"""Typed, immutable domain model parsed from config.toml."""

import os
from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class Source:
    name: str
    url: str
    checksum_type: str
    checksum_url: str | None
    arch_map: dict[str, str] = field(default_factory=dict)
    ext_map: dict[str, str] = field(default_factory=dict)
    platform_map: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class Package:
    name: str
    platform: str
    details: dict[str, Any]
    source: Source


@dataclass(frozen=True)
class BuildTarget:
    package: Package
    arch: str

    @property
    def platform(self) -> str:
        return self.package.platform

    def format_url(self) -> str:
        source = self.package.source
        ext = source.ext_map.get(self.platform) or source.ext_map["default"]
        platform = source.platform_map.get(self.platform) or self.platform
        return source.url.format(
            platform=platform,
            arch=source.arch_map.get(self.arch) or self.arch,
            name=self.package.name,
            ext=ext,
            **self.package.details,
        )

    def cache_filename(self) -> str:
        return f"{self.platform}-{self.arch}-{os.path.basename(self.format_url())}"


@dataclass(frozen=True)
class Config:
    version: int
    platforms: dict[str, list[str]]
    sources: dict[str, Source]
    packages: list[Package]

    def platform_arch_pairs(self) -> list[tuple[str, str]]:
        return [(p, a) for p, arches in self.platforms.items() for a in arches]

    def build_targets(self) -> list["BuildTarget"]:
        pairs = self.platform_arch_pairs()
        return [
            BuildTarget(pkg, arch)
            for pkg in self.packages
            for platform, arch in pairs
            if pkg.platform == platform
        ]
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_model_url.py -v`
Expected: all three tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/model.py tests/test_model_url.py
git commit -m "Add typed domain model (Source, Package, BuildTarget, Config)"
```

---

### Task 3: Config loader (`config.py`)

**Files:**
- Create: `src/dbtbuilder/config.py`
- Test: `tests/test_config.py`

**Interfaces:**
- Consumes: `model.Source`, `model.Package`, `model.Config`; `errors.ConfigError`.
- Produces:
  - `load_config(path: Path) -> Config` (opens the TOML file, calls `parse_config`).
  - `parse_config(raw: dict) -> Config`. Replicates the monolith's parsing: builds `Source`s (defaults `checksum_type="sha256"`, empty maps), expands packages — a package with a top-level `source` applies to every platform; otherwise each key is a platform, and a `default` key applies to all platforms **not** otherwise listed. Resolves each package's `source` (string, or per-platform dict) to a `Source`. Raises `ConfigError` on missing keys, unknown source references, or a missing per-platform source.

- [ ] **Step 1: Write the failing test — `tests/test_config.py`**

```python
import pytest

from dbtbuilder.config import parse_config
from dbtbuilder.errors import ConfigError

RAW = {
    "version": 25,
    "platforms": {
        "linux": {"arch": ["x86_64", "arm64"]},
        "win32": {"arch": ["x86_64"]},
    },
    "sources": {
        "xpack": {
            "url": "http://x/{name}-{version}-{platform}-{arch}.{ext}",
            "checksum_url": "{url}.sha",
            "ext": {"default": "tar.gz", "win32": "zip"},
            "arch": {"x86_64": "x64"},
        },
        "rust": {"url": "http://r/{name}{ext}", "ext": {"default": "", "win32": ".exe"}},
    },
    "packages": {
        "cmake": {"version": "1.0", "source": "xpack"},
        "special": {
            "default": {"version": "2.0", "source": "rust"},
            "win32": {"version": "2.0", "source": "rust", "set-executable": True},
        },
    },
}


def test_source_defaults_checksum_type_to_sha256():
    cfg = parse_config(RAW)
    assert cfg.sources["xpack"].checksum_type == "sha256"


def test_package_with_top_level_source_expands_to_all_platforms():
    cfg = parse_config(RAW)
    cmake = [p for p in cfg.packages if p.name == "cmake"]
    assert {p.platform for p in cmake} == {"linux", "win32"}
    assert all(p.source.name == "xpack" for p in cmake)


def test_default_key_applies_only_to_non_overridden_platforms():
    cfg = parse_config(RAW)
    special = {p.platform: p for p in cfg.packages if p.name == "special"}
    assert set(special) == {"linux", "win32"}
    assert special["linux"].details.get("set-executable") is None
    assert special["win32"].details.get("set-executable") is True
    assert special["linux"].source.name == "rust"


def test_unknown_source_raises_config_error():
    bad = {
        "version": 1,
        "platforms": {"linux": {"arch": ["x86_64"]}},
        "sources": {},
        "packages": {"x": {"version": "1", "source": "nope"}},
    }
    with pytest.raises(ConfigError):
        parse_config(bad)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_config.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.config'`.

- [ ] **Step 3: Create `src/dbtbuilder/config.py`**

```python
"""Parse config.toml into the typed Config model."""

import tomllib
from pathlib import Path
from typing import Any

from .errors import ConfigError
from .model import Config, Package, Source


def load_config(path: Path) -> Config:
    with open(path, "rb") as f:
        return parse_config(tomllib.load(f))


def parse_config(raw: dict[str, Any]) -> Config:
    try:
        version = raw["version"]
        platforms = {p: list(d["arch"]) for p, d in raw["platforms"].items()}
    except KeyError as e:
        raise ConfigError(f"config is missing required key: {e}") from e

    sources = {
        name: Source(
            name=name,
            url=d["url"],
            checksum_type=d.get("checksum_type") or "sha256",
            checksum_url=d.get("checksum_url"),
            arch_map=d.get("arch") or {},
            ext_map=d.get("ext") or {},
            platform_map=d.get("platform") or {},
        )
        for name, d in raw["sources"].items()
    }

    packages: list[Package] = []
    for name, details in raw["packages"].items():
        packages.extend(_expand_package(name, details, platforms, sources))

    return Config(
        version=version, platforms=platforms, sources=sources, packages=packages
    )


def _expand_package(
    name: str,
    details: dict[str, Any],
    platforms: dict[str, list[str]],
    sources: dict[str, Source],
) -> list[Package]:
    if "source" in details:
        return [_make_package(name, p, details, sources) for p in platforms]

    result: list[Package] = []
    for platform, info in details.items():
        if platform == "default":
            result.extend(
                _make_package(name, p, info, sources)
                for p in platforms
                if p not in details
            )
        else:
            result.append(_make_package(name, platform, info, sources))
    return result


def _make_package(
    name: str,
    platform: str,
    details: dict[str, Any],
    sources: dict[str, Source],
) -> Package:
    return Package(
        name=name,
        platform=platform,
        details=details,
        source=_resolve_source(name, platform, details, sources),
    )


def _resolve_source(
    name: str,
    platform: str,
    details: dict[str, Any],
    sources: dict[str, Source],
) -> Source:
    try:
        source_key = details["source"]
    except KeyError as e:
        raise ConfigError(f"package '{name}' ({platform}) has no 'source'") from e

    if isinstance(source_key, dict):
        try:
            source_key = source_key[platform]
        except KeyError as e:
            raise ConfigError(
                f"package '{name}' has no source for platform '{platform}'"
            ) from e

    try:
        return sources[source_key]
    except KeyError as e:
        raise ConfigError(
            f"package '{name}' references unknown source '{source_key}'"
        ) from e
```

- [ ] **Step 4: Run the test to verify it passes, and check the real config parses**

Run:
```bash
python -m pytest tests/test_config.py -v
python -c "from pathlib import Path; from dbtbuilder.config import load_config; c = load_config(Path('config.toml')); print(c.version, len(c.build_targets()), 'targets')"
```
Expected: tests PASS; the second command prints `25 <N> targets` with no exception (proves the real `config.toml` still parses and every source resolves).

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/config.py tests/test_config.py
git commit -m "Add config.toml parser with validation"
```

---

### Task 4: Injectable paths (`paths.py`)

**Files:**
- Create: `src/dbtbuilder/paths.py`
- Test: `tests/test_paths.py`

**Interfaces:**
- Produces: `BuildPaths(root: Path)` frozen dataclass with `.from_root(root: Path | None = None) -> BuildPaths` (defaults to resolved cwd), properties `.dist`, `.staging`, `.cache` (`root/dist`, `root/staging`, `root/cache`), and `.staging_dir(platform, arch) -> Path` (`staging/{platform}-{arch}`).

- [ ] **Step 1: Write the failing test — `tests/test_paths.py`**

```python
from pathlib import Path

from dbtbuilder.paths import BuildPaths


def test_paths_derive_from_root(tmp_path):
    p = BuildPaths.from_root(tmp_path)
    assert p.dist == tmp_path / "dist"
    assert p.staging == tmp_path / "staging"
    assert p.cache == tmp_path / "cache"
    assert p.staging_dir("linux", "x86_64") == tmp_path / "staging" / "linux-x86_64"


def test_from_root_defaults_to_cwd():
    p = BuildPaths.from_root()
    assert p.root == Path.cwd().resolve()
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_paths.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.paths'`.

- [ ] **Step 3: Create `src/dbtbuilder/paths.py`**

```python
"""Filesystem locations for a build, derived from a single root directory.

Passed explicitly to the I/O functions so tests can point a build at a tmp dir
instead of the process working directory.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class BuildPaths:
    root: Path

    @classmethod
    def from_root(cls, root: Path | None = None) -> "BuildPaths":
        return cls(root=(root or Path.cwd()).resolve())

    @property
    def dist(self) -> Path:
        return self.root / "dist"

    @property
    def staging(self) -> Path:
        return self.root / "staging"

    @property
    def cache(self) -> Path:
        return self.root / "cache"

    def staging_dir(self, platform: str, arch: str) -> Path:
        return self.staging / f"{platform}-{arch}"
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_paths.py -v`
Expected: both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/paths.py tests/test_paths.py
git commit -m "Add injectable BuildPaths"
```

---

### Task 5: HTTP layer and checksum verification (`http.py`, `checksum.py`)

**Files:**
- Create: `src/dbtbuilder/http.py`
- Create: `src/dbtbuilder/checksum.py`
- Create: `tests/conftest.py`
- Test: `tests/test_checksum.py`

**Interfaces:**
- Consumes: `errors.DownloadError`, `errors.ChecksumMismatch`.
- Produces:
  - `http.fetch_text(url: str) -> str` (GET body as text; raises `DownloadError`).
  - `http.download_file(url: str, dest: Path) -> Path` (streams to `dest` with a tqdm bar, creating parent dirs; raises `DownloadError`).
  - `checksum.file_digest(path: Path, algo: str) -> str` (hex digest).
  - `checksum.verify_remote(path: Path, algo: str, checksum_url: str) -> None` (fetches the published checksum, compares the first whitespace-delimited token to the local digest; raises `ChecksumMismatch` on mismatch).
  - Test fixture `http_server` (in `conftest.py`): yields `(base_url, served_dir)` for a localhost `http.server` rooted at a temp dir.

- [ ] **Step 1: Create the local-server fixture — `tests/conftest.py`**

```python
import functools
import http.server
import socketserver
import threading

import pytest


@pytest.fixture
def http_server(tmp_path):
    """Serve tmp_path/'srv' over localhost; yields (base_url, served_dir)."""
    served = tmp_path / "srv"
    served.mkdir()
    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler, directory=str(served)
    )
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", 0), handler)
    port = httpd.server_address[1]
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{port}", served
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()
```

- [ ] **Step 2: Write the failing test — `tests/test_checksum.py`**

```python
import hashlib

import pytest

from dbtbuilder import checksum
from dbtbuilder.errors import ChecksumMismatch


def test_verify_remote_accepts_matching_digest(http_server):
    base, served = http_server
    payload = served / "payload.bin"
    payload.write_bytes(b"hello world")
    digest = hashlib.sha256(payload.read_bytes()).hexdigest()
    (served / "payload.bin.sha256").write_text(f"{digest}  payload.bin\n")

    # Should not raise.
    checksum.verify_remote(payload, "sha256", f"{base}/payload.bin.sha256")


def test_verify_remote_rejects_wrong_digest(http_server):
    base, served = http_server
    payload = served / "payload.bin"
    payload.write_bytes(b"hello world")
    (served / "payload.bin.sha256").write_text("deadbeef  payload.bin\n")

    with pytest.raises(ChecksumMismatch):
        checksum.verify_remote(payload, "sha256", f"{base}/payload.bin.sha256")
```

- [ ] **Step 3: Run it to verify it fails**

Run: `python -m pytest tests/test_checksum.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.checksum'`.

- [ ] **Step 4: Create `src/dbtbuilder/http.py`**

```python
"""The single HTTP path for dbtbuilder (downloads and checksum fetches)."""

from pathlib import Path

import requests
from tqdm.rich import tqdm

from .errors import DownloadError

_TIMEOUT = 60


def fetch_text(url: str) -> str:
    try:
        response = requests.get(url, timeout=_TIMEOUT, allow_redirects=True)
        response.raise_for_status()
    except requests.RequestException as e:
        raise DownloadError(f"failed to fetch {url}: {e}") from e
    return response.text


def download_file(url: str, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    block_size = 1024
    try:
        with requests.get(
            url, stream=True, allow_redirects=True, timeout=_TIMEOUT
        ) as response:
            response.raise_for_status()
            file_size = int(response.headers.get("Content-Length", 0))
            with tqdm(
                total=file_size,
                unit="B",
                unit_scale=True,
                miniters=0.01,
                desc=dest.name,
            ) as pbar:
                with dest.open("wb") as f:
                    for data in response.iter_content(block_size):
                        f.write(data)
                        pbar.update(len(data))
                        pbar.refresh()
                pbar.refresh()
    except requests.RequestException as e:
        raise DownloadError(f"failed to download {url}: {e}") from e
    return dest
```

- [ ] **Step 5: Create `src/dbtbuilder/checksum.py`**

```python
"""Digest computation and remote-checksum verification."""

import hashlib
from pathlib import Path

from . import http
from .errors import ChecksumMismatch


def file_digest(path: Path, algo: str) -> str:
    with open(path, "rb", buffering=0) as f:
        return hashlib.file_digest(f, algo).hexdigest()


def verify_remote(path: Path, algo: str, checksum_url: str) -> None:
    expected = http.fetch_text(checksum_url).strip().split()[0]
    actual = file_digest(path, algo)
    if actual != expected:
        raise ChecksumMismatch(
            f"{algo.upper()} mismatch for {path.name}: "
            f"expected {expected}, got {actual}"
        )
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `python -m pytest tests/test_checksum.py -v`
Expected: both tests PASS.

- [ ] **Step 7: Commit**

```bash
git add src/dbtbuilder/http.py src/dbtbuilder/checksum.py tests/conftest.py tests/test_checksum.py
git commit -m "Add unified HTTP layer and checksum verification"
```

---

### Task 6: Download a build target (`download.py`)

**Files:**
- Create: `src/dbtbuilder/download.py`
- Test: `tests/test_download.py`

**Interfaces:**
- Consumes: `model.BuildTarget`, `paths.BuildPaths`, `http.download_file`, `checksum.verify_remote`.
- Produces: `download_target(target: BuildTarget, paths: BuildPaths) -> None`. Resolves the URL and (if the source has a `checksum_url`) formats it with `url` / `url_no_ext`. If the cache file exists **and** a checksum URL is configured, verifies it and returns (skip re-download); otherwise downloads then verifies (when a checksum URL exists). Applies `chmod 0o755` to the cache file when `details['set-executable']` is set. Verification failures raise `ChecksumMismatch`; download failures raise `DownloadError`.

- [ ] **Step 1: Write the failing test — `tests/test_download.py`**

```python
import hashlib

from dbtbuilder import download
from dbtbuilder.model import BuildTarget, Package, Source
from dbtbuilder.paths import BuildPaths


def test_download_target_writes_and_verifies(http_server, tmp_path):
    base, served = http_server
    payload = served / "payload.bin"
    payload.write_bytes(b"toolchain-bytes")
    digest = hashlib.sha256(payload.read_bytes()).hexdigest()
    (served / "payload.bin.sha256").write_text(f"{digest}\n")

    src = Source(
        name="t",
        url=f"{base}/payload.bin",
        checksum_type="sha256",
        checksum_url="{url}.sha256",
        ext_map={"default": ""},
    )
    pkg = Package("payload", "linux", {"source": "t"}, src)
    target = BuildTarget(pkg, "x86_64")

    paths = BuildPaths.from_root(tmp_path / "work")
    download.download_target(target, paths)

    cached = paths.cache / "linux-x86_64-payload.bin"
    assert cached.is_file()
    assert cached.read_bytes() == b"toolchain-bytes"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_download.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.download'`.

- [ ] **Step 3: Create `src/dbtbuilder/download.py`**

```python
"""Fetch a single build target into the cache, verifying its checksum."""

import os

from . import checksum, http
from .model import BuildTarget
from .paths import BuildPaths


def download_target(target: BuildTarget, paths: BuildPaths) -> None:
    source = target.package.source
    url = target.format_url()

    checksum_url = None
    if source.checksum_url:
        checksum_url = source.checksum_url.format(
            url=url, url_no_ext=os.path.splitext(url)[0]
        )

    filepath = paths.cache / target.cache_filename()

    if filepath.is_file() and checksum_url:
        # Cached and verifiable: confirm and skip the re-download.
        checksum.verify_remote(filepath, source.checksum_type, checksum_url)
        return

    http.download_file(url, filepath)
    if checksum_url:
        checksum.verify_remote(filepath, source.checksum_type, checksum_url)

    if target.package.details.get("set-executable", False):
        os.chmod(filepath, 0o755)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_download.py -v`
Expected: test PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/download.py tests/test_download.py
git commit -m "Add download_target with cache reuse and checksum verify"
```

---

### Task 7: Extract archives and raw binaries (`extract.py`)

**Files:**
- Create: `src/dbtbuilder/extract.py`
- Test: `tests/test_extract.py`

**Interfaces:**
- Consumes: `model.BuildTarget`, `paths.BuildPaths`, `errors.ExtractError`.
- Produces:
  - `extract_target(target: BuildTarget, paths: BuildPaths, force_reextract: bool = False) -> None`. If the cache file has no suffix or a `.exe` suffix, copies it to `staging/{platform}-{arch}/{name}/{name}{suffix}` and re-applies `0o755` when `set-executable`. Otherwise picks `unzip_archive` (ext `zip`) or `untar_archive`, honours `force_reextract`, and calls `shift_subdir_up`. The include list is read from `paths.root / "config" / f"{platform}-{arch}-{name}.include"` when present.
  - `untar_archive(tar_file, dest_dir, include_list) -> None` / `unzip_archive(zip_file, dest_dir, include_list) -> None`. Clear and recreate `dest_dir`, optionally filter members by the include list (each line joined to the archive's common root prefix), extract with a tqdm bar. Any `tarfile`/`zipfile`/OS error raises `ExtractError` (no silent swallow).
  - `shift_subdir_up(parent_dir: str, dest_path: Path) -> None`. When `dest_path/parent_dir` has a single child directory, hoists that child's contents up one level.

- [ ] **Step 1: Write the failing test — `tests/test_extract.py`**

```python
import os
import stat
import tarfile

import pytest

from dbtbuilder import extract
from dbtbuilder.errors import ExtractError
from dbtbuilder.model import BuildTarget, Package, Source
from dbtbuilder.paths import BuildPaths


def test_shift_subdir_up_flattens_single_child(tmp_path):
    inner = tmp_path / "pkg" / "pkg-1.0" / "bin"
    inner.mkdir(parents=True)
    (inner / "tool").write_text("x")

    extract.shift_subdir_up("pkg", tmp_path)

    assert (tmp_path / "pkg" / "bin" / "tool").read_text() == "x"
    assert not (tmp_path / "pkg" / "pkg-1.0").exists()


def test_extract_raw_binary_stages_and_sets_exec_bit(tmp_path):
    paths = BuildPaths.from_root(tmp_path / "work")
    paths.cache.mkdir(parents=True)
    (paths.cache / "linux-x86_64-rustup-init").write_bytes(b"#!/bin/sh\n")

    src = Source(
        name="rust",
        url="http://example/rustup-init",
        checksum_type="sha256",
        checksum_url=None,
        ext_map={"default": ""},
    )
    pkg = Package(
        "rustup-init", "linux", {"source": "rust", "set-executable": True}, src
    )
    extract.extract_target(BuildTarget(pkg, "x86_64"), paths)

    staged = paths.staging_dir("linux", "x86_64") / "rustup-init" / "rustup-init"
    assert staged.is_file()
    assert os.stat(staged).st_mode & stat.S_IXUSR


def test_untar_archive_applies_include_filter(tmp_path):
    content = tmp_path / "content" / "pkg-1.0" / "bin"
    content.mkdir(parents=True)
    (content / "keep").write_text("keep")
    (content / "drop").write_text("drop")
    tar_path = tmp_path / "archive.tar"
    with tarfile.open(tar_path, "w") as tar:
        tar.add(tmp_path / "content" / "pkg-1.0", arcname="pkg-1.0")

    include = tmp_path / "inc.txt"
    include.write_text("bin/keep\n")
    dest = tmp_path / "out"

    extract.untar_archive(tar_path, dest, include)

    files = {p.name for p in dest.rglob("*") if p.is_file()}
    assert "keep" in files
    assert "drop" not in files


def test_untar_archive_raises_on_corrupt_file(tmp_path):
    bad = tmp_path / "bad.tar"
    bad.write_text("not a tar at all")
    with pytest.raises(ExtractError):
        extract.untar_archive(bad, tmp_path / "out", tmp_path / "missing.include")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_extract.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.extract'`.

- [ ] **Step 3: Create `src/dbtbuilder/extract.py`**

```python
"""Extract downloaded archives (or copy raw binaries) into staging."""

import os
import shutil
import tarfile
import zipfile
from pathlib import Path

from tqdm.rich import tqdm

from .errors import ExtractError
from .model import BuildTarget
from .paths import BuildPaths


def extract_target(
    target: BuildTarget, paths: BuildPaths, force_reextract: bool = False
) -> None:
    package = target.package
    platform, arch = target.platform, target.arch
    dest_path = paths.staging_dir(platform, arch) / package.name
    filepath = paths.cache / target.cache_filename()

    # Raw binary or bare file: copy it straight into staging.
    if not filepath.suffix or filepath.suffix == ".exe":
        dest_file = dest_path / (package.name + filepath.suffix)
        dest_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(filepath, dest_file)
        # copyfile drops permissions; re-apply the exec bit to the staged (packaged)
        # file when the package asks for it.
        if package.details.get("set-executable", False):
            os.chmod(dest_file, 0o755)
        return

    # Archive: extract (optionally filtered) then flatten the single top dir.
    source = package.source
    ext = source.ext_map.get(platform) or source.ext_map["default"]
    include_file = paths.root / "config" / f"{platform}-{arch}-{package.name}.include"

    extractor = unzip_archive if ext == "zip" else untar_archive

    if force_reextract and dest_path.exists():
        shutil.rmtree(dest_path)

    if force_reextract or not dest_path.exists():
        extractor(filepath, dest_path, include_file)
        shift_subdir_up(package.name, dest_path.parent)


def shift_subdir_up(parent_dir: str, dest_path: Path) -> None:
    subdir_path = dest_path / parent_dir

    if len(list(subdir_path.iterdir())) < 2:
        subdir = next(subdir_path.iterdir()).name
        wrong_subdir_path = subdir_path.rename(dest_path / f"{parent_dir}.wrong")
        (wrong_subdir_path / subdir).rename(subdir_path)
        wrong_subdir_path.rmdir()


def untar_archive(tar_file: Path, dest_dir: Path, include_list: Path) -> None:
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    try:
        with tarfile.open(tar_file, "r") as tar:
            members = tar.getmembers()
            if include_list.is_file():
                root_dir = os.path.commonprefix(tar.getnames())
                with open(include_list) as f:
                    includes = [f"{root_dir}/{line.strip()}" for line in f]
                members = [m for m in members if m.name in includes]

            with tqdm(total=len(members), desc=tar_file.name, unit="files") as pbar:
                for member in members:
                    tar.extract(member, path=dest_dir, filter="data")
                    pbar.update(1)
                    pbar.refresh()
                pbar.refresh()
    except (tarfile.TarError, OSError) as e:
        raise ExtractError(f"failed to extract {tar_file.name}: {e}") from e


def unzip_archive(zip_file: Path, dest_dir: Path, include_list: Path) -> None:
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    try:
        with zipfile.ZipFile(zip_file, "r") as zip_ref:
            zip_includes: list[str] = []
            if include_list.is_file():
                root_dir = os.path.commonprefix(zip_ref.namelist())
                with open(include_list) as f:
                    zip_includes = [f"{root_dir}{line.strip()}" for line in f]

            total = len(zip_includes) if zip_includes else len(zip_ref.infolist())
            with tqdm(total=total, desc=zip_file.name, unit="files") as pbar:
                for info in zip_ref.infolist():
                    if not zip_includes or info.filename in zip_includes:
                        zip_ref.extract(info, dest_dir)
                        pbar.update(1)
                        pbar.refresh()
                pbar.refresh()
    except (zipfile.BadZipFile, OSError) as e:
        raise ExtractError(f"failed to extract {zip_file.name}: {e}") from e
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_extract.py -v`
Expected: all four tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/extract.py tests/test_extract.py
git commit -m "Add extract_target with fail-fast archive handling"
```

---

### Task 8: Python wheel bundling (`wheels.py`)

**Files:**
- Create: `src/dbtbuilder/wheels.py`
- Test: `tests/test_wheels.py`

**Interfaces:**
- Consumes: `paths.BuildPaths`, `errors.DbtBuilderError`.
- Produces:
  - `get_sysname_arch() -> tuple[str, str]` (host platform/arch; `("win32", "x86_64")` on Windows, else lowercased `os.uname()`).
  - `add_python_lib(lib_name: str, platform_arch_pairs: list[tuple[str, str]], paths: BuildPaths) -> None`. Builds the wheel(s) into the host toolchain's `python/wheel` dir via the staged interpreter's `pip wheel`, then copies them into every other platform's `python/wheel` dir. Raises `DbtBuilderError` if `pip wheel` fails (previously swallowed).

- [ ] **Step 1: Write the failing test — `tests/test_wheels.py`**

```python
from dbtbuilder import wheels
from dbtbuilder.paths import BuildPaths


def test_add_python_lib_copies_wheels_to_other_platforms(monkeypatch, tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    monkeypatch.setattr(wheels, "get_sysname_arch", lambda: ("linux", "x86_64"))

    fake_wheel = tmp_path / "foo-1.0-py3-none-any.whl"
    fake_wheel.write_text("wheel-bytes")

    def fake_check_output(cmd, stderr=None):
        return f"Saved {fake_wheel}\n".encode()

    monkeypatch.setattr(wheels.subprocess, "check_output", fake_check_output)

    wheels.add_python_lib("foo", [("linux", "x86_64"), ("darwin", "arm64")], paths)

    copied = paths.staging_dir("darwin", "arm64") / "python" / "wheel" / fake_wheel.name
    assert copied.is_file()
    assert copied.read_text() == "wheel-bytes"


def test_add_python_lib_raises_when_pip_fails(monkeypatch, tmp_path):
    import subprocess

    from dbtbuilder.errors import DbtBuilderError

    paths = BuildPaths.from_root(tmp_path)
    monkeypatch.setattr(wheels, "get_sysname_arch", lambda: ("linux", "x86_64"))

    def boom(cmd, stderr=None):
        raise subprocess.CalledProcessError(1, cmd, output=b"pip exploded")

    monkeypatch.setattr(wheels.subprocess, "check_output", boom)

    try:
        wheels.add_python_lib("foo", [("linux", "x86_64")], paths)
    except DbtBuilderError:
        return
    raise AssertionError("expected DbtBuilderError")
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_wheels.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.wheels'`.

- [ ] **Step 3: Create `src/dbtbuilder/wheels.py`**

```python
"""Build and distribute pure-Python wheels into every toolchain's python/wheel."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from .errors import DbtBuilderError
from .paths import BuildPaths


def get_sysname_arch() -> tuple[str, str]:
    if sys.platform == "win32":
        return "win32", "x86_64"
    return os.uname().sysname.lower(), os.uname().machine.lower()


def add_python_lib(
    lib_name: str,
    platform_arch_pairs: list[tuple[str, str]],
    paths: BuildPaths,
) -> None:
    sysname, arch = get_sysname_arch()
    this_path = paths.staging_dir(sysname, arch)

    if sysname == "win32":
        py_bin = this_path / "python/python.exe"
    else:
        py_bin = this_path / "python/bin/python3"

    wheel_dir = this_path / "python/wheel"
    wheel_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        str(py_bin),
        "-m",
        "pip",
        "--disable-pip-version-check",
        "wheel",
        "--wheel-dir",
        str(wheel_dir),
        lib_name,
    ]
    print(f"Installing python lib '{lib_name}'")
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        detail = e.output.decode(errors="replace") if e.output else ""
        raise DbtBuilderError(f"pip wheel failed for '{lib_name}': {detail}") from e
    print(output.decode())

    wheel_files = [
        Path(line.strip().decode().split()[-1])
        for line in output.splitlines()
        if line.strip().decode().endswith(".whl")
    ]

    for os_label, os_arch in platform_arch_pairs:
        target_path = paths.staging_dir(os_label, os_arch)
        if target_path != this_path:
            target_wheel = target_path / "python/wheel"
            target_wheel.mkdir(parents=True, exist_ok=True)
            for wheel in wheel_files:
                shutil.copy(wheel, target_wheel / wheel.name)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_wheels.py -v`
Expected: both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/wheels.py tests/test_wheels.py
git commit -m "Add wheel bundling that fails loudly on pip errors"
```

---

### Task 9: Package the dist archives (`package.py`)

**Files:**
- Create: `src/dbtbuilder/package.py`
- Test: `tests/test_package.py`

**Interfaces:**
- Consumes: `paths.BuildPaths`.
- Produces:
  - `create_tar_gz(src_dir: Path, dest_file: Path) -> None` (`w:gz`, `compresslevel=6`, `arcname` relative to `src_dir.parent`, `recursive=False` per member).
  - `create_zip(src_dir: Path, dest_file: Path) -> None` (`ZIP_DEFLATED`, `arcname` relative to `src_dir.parent`).
  - `package_dist(version: int, platform: str, arch: str, paths: BuildPaths) -> None`. No-op if the staging dir is missing. Writes `VERSION` (`f"{version}\n"`) into staging, builds `dist/dbt-toolchain-{version}-{platform}-{arch}.zip` on win32 else `.tar.gz`, and writes `{archive}.md5` / `{archive}.sha256` sidecars (bare hex digest, no newline).

- [ ] **Step 1: Write the failing test — `tests/test_package.py`**

```python
import hashlib
import tarfile

from dbtbuilder import package
from dbtbuilder.paths import BuildPaths


def test_package_dist_builds_tar_with_prefixed_members_and_hashes(tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    staging = paths.staging_dir("linux", "x86_64")
    (staging / "bin").mkdir(parents=True)
    (staging / "bin" / "tool").write_text("hi")
    paths.dist.mkdir(parents=True)

    package.package_dist(25, "linux", "x86_64", paths)

    archive = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz"
    assert archive.is_file()

    md5_file = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz.md5"
    sha_file = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz.sha256"
    assert md5_file.read_text() == hashlib.md5(archive.read_bytes()).hexdigest()
    assert sha_file.read_text() == hashlib.sha256(archive.read_bytes()).hexdigest()

    with tarfile.open(archive) as t:
        names = set(t.getnames())
    assert "linux-x86_64/VERSION" in names
    assert "linux-x86_64/bin/tool" in names


def test_package_dist_noop_when_staging_missing(tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    paths.dist.mkdir(parents=True)
    package.package_dist(25, "linux", "arm64", paths)  # no staging dir
    assert list(paths.dist.iterdir()) == []
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_package.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.package'`.

- [ ] **Step 3: Create `src/dbtbuilder/package.py`**

```python
"""Compress each staged toolchain into a dist archive with hash sidecars."""

import hashlib
import tarfile
import zipfile
from pathlib import Path

from tqdm.rich import tqdm

from .paths import BuildPaths


def create_tar_gz(src_dir: Path, dest_file: Path) -> None:
    with tarfile.open(dest_file, "w:gz", compresslevel=6) as tar:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                tar.add(
                    file, arcname=file.relative_to(src_dir.parent), recursive=False
                )
                pbar.update(1)
                pbar.refresh()


def create_zip(src_dir: Path, dest_file: Path) -> None:
    with zipfile.ZipFile(dest_file, "w", zipfile.ZIP_DEFLATED) as zipf:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                zipf.write(file, arcname=file.relative_to(src_dir.parent))
                pbar.update(1)
                pbar.refresh()


def _write_hash(archive: Path, algo: str) -> None:
    with open(archive, "rb", buffering=0) as f:
        digest = hashlib.file_digest(f, algo).hexdigest()
    (archive.parent / f"{archive.name}.{algo}").write_text(digest)


def package_dist(version: int, platform: str, arch: str, paths: BuildPaths) -> None:
    staging = paths.staging_dir(platform, arch)
    if not staging.is_dir():
        return

    (staging / "VERSION").write_text(f"{version}\n")

    name = f"dbt-toolchain-{version}-{platform}-{arch}"
    if platform == "win32":
        archive = paths.dist / f"{name}.zip"
        create_zip(staging, archive)
    else:
        archive = paths.dist / f"{name}.tar.gz"
        create_tar_gz(staging, archive)

    _write_hash(archive, "md5")
    _write_hash(archive, "sha256")
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_package.py -v`
Expected: both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/package.py tests/test_package.py
git commit -m "Add dist packaging with md5/sha256 sidecars"
```

---

### Task 10: Orchestrate the build phases (`orchestrate.py`)

**Files:**
- Create: `src/dbtbuilder/orchestrate.py`
- Test: `tests/test_orchestrate.py`

**Interfaces:**
- Consumes: `model.Config`, `paths.BuildPaths`, and the modules `download`, `extract`, `wheels`, `package`.
- Produces: `run_build(config, paths, *, platforms=None, arches=None, force=False, only=None) -> None`. Builds the target list from `config.build_targets()`, optionally filtered by `platforms` / `arches`. Creates `staging`. Runs the phases gated by `only` (`None` = all): **download** every target; **extract** every target (`force_reextract=force`); **wheels** for `certifi`, `ansi`, `setuptools==75.8.0`; **package** — wipes and recreates `dist`, then packages each `(platform, arch)` pair. Phase order matches the monolith.

- [ ] **Step 1: Write the failing test — `tests/test_orchestrate.py`**

```python
from dbtbuilder import orchestrate
from dbtbuilder.model import Config, Package, Source
from dbtbuilder.paths import BuildPaths


def _tiny_config():
    src = Source("s", "http://x/{name}", "sha256", None, ext_map={"default": ""})
    packages = [
        Package("a", "linux", {"source": "s"}, src),
        Package("a", "darwin", {"source": "s"}, src),
    ]
    return Config(
        version=25,
        platforms={"linux": ["x86_64"], "darwin": ["arm64"]},
        sources={"s": src},
        packages=packages,
    )


def test_only_download_runs_download_and_nothing_else(monkeypatch, tmp_path):
    calls = []
    monkeypatch.setattr(
        orchestrate.download, "download_target", lambda t, p: calls.append("dl")
    )
    monkeypatch.setattr(
        orchestrate.extract, "extract_target", lambda *a, **k: calls.append("ex")
    )
    monkeypatch.setattr(
        orchestrate.wheels, "add_python_lib", lambda *a, **k: calls.append("wh")
    )
    monkeypatch.setattr(
        orchestrate.package, "package_dist", lambda *a, **k: calls.append("pk")
    )

    orchestrate.run_build(
        _tiny_config(), BuildPaths.from_root(tmp_path), only="download"
    )

    assert calls == ["dl", "dl"]  # two targets, download only


def test_platform_filter_restricts_targets(monkeypatch, tmp_path):
    seen = []
    monkeypatch.setattr(
        orchestrate.download, "download_target", lambda t, p: seen.append(t.platform)
    )
    monkeypatch.setattr(orchestrate.extract, "extract_target", lambda *a, **k: None)
    monkeypatch.setattr(orchestrate.wheels, "add_python_lib", lambda *a, **k: None)
    monkeypatch.setattr(orchestrate.package, "package_dist", lambda *a, **k: None)

    orchestrate.run_build(
        _tiny_config(),
        BuildPaths.from_root(tmp_path),
        platforms=["linux"],
        only="download",
    )

    assert set(seen) == {"linux"}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_orchestrate.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.orchestrate'`.

- [ ] **Step 3: Create `src/dbtbuilder/orchestrate.py`**

```python
"""Drive the download -> extract -> wheels -> package pipeline."""

import shutil

from rich import print as rich_print

from . import download, extract, package, wheels
from .model import Config
from .paths import BuildPaths

_WHEEL_LIBS = ("certifi", "ansi", "setuptools==75.8.0")


def run_build(
    config: Config,
    paths: BuildPaths,
    *,
    platforms: list[str] | None = None,
    arches: list[str] | None = None,
    force: bool = False,
    only: str | None = None,
) -> None:
    targets = config.build_targets()
    pairs = config.platform_arch_pairs()
    if platforms:
        targets = [t for t in targets if t.platform in platforms]
        pairs = [(p, a) for p, a in pairs if p in platforms]
    if arches:
        targets = [t for t in targets if t.arch in arches]
        pairs = [(p, a) for p, a in pairs if a in arches]

    paths.staging.mkdir(exist_ok=True)

    if only in (None, "download"):
        rich_print(r"[bold dim]\[1/3][/bold dim] Downloading...")
        for target in targets:
            download.download_target(target, paths)

    if only in (None, "extract"):
        rich_print(r"[bold dim]\[2/3][/bold dim] Extracting...")
        for target in targets:
            extract.extract_target(target, paths, force_reextract=force)

    if only in (None, "wheels"):
        for lib in _WHEEL_LIBS:
            wheels.add_python_lib(lib, pairs, paths)

    if only in (None, "package"):
        if paths.dist.exists():
            shutil.rmtree(paths.dist)
        paths.dist.mkdir()
        rich_print(r"[bold dim]\[3/3][/bold dim] Compressing toolpacks...")
        for platform, arch in pairs:
            package.package_dist(config.version, platform, arch, paths)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m pytest tests/test_orchestrate.py -v`
Expected: both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/dbtbuilder/orchestrate.py tests/test_orchestrate.py
git commit -m "Add build orchestrator with phase and platform selection"
```

---

### Task 11: CLI entry point (`cli.py`, `__main__.py`)

**Files:**
- Create: `src/dbtbuilder/cli.py`
- Create: `src/dbtbuilder/__main__.py`
- Test: `tests/test_cli.py`

**Interfaces:**
- Consumes: `config.load_config`, `paths.BuildPaths`, `orchestrate.run_build`, `errors.DbtBuilderError`, `__version__`.
- Produces:
  - `build_parser() -> argparse.ArgumentParser` with `--config` (default `config.toml`), `--root`, `--platform` (repeatable, choices `linux`/`darwin`/`win32`), `--arch` (repeatable), `--force`, `--only` (choices `download`/`extract`/`wheels`/`package`), `-v/--verbose`, `--version`, `--toolchain-version`.
  - `main(argv: list[str] | None = None) -> int`. Loads config; if `--toolchain-version`, prints `config.version` and returns 0; otherwise builds `BuildPaths` and calls `run_build`. Catches `DbtBuilderError`, prints it in red, returns 1. On success prints the `=^._.^= DONE =^._.^=` banner and returns 0.
  - `__main__.py` runs `sys.exit(main())`.

- [ ] **Step 1: Write the failing test — `tests/test_cli.py`**

```python
from dbtbuilder import cli
from dbtbuilder.errors import DbtBuilderError

_CONFIG = (
    "version = 42\n"
    "[platforms]\n[platforms.linux]\narch = [\"x86_64\"]\n"
    "[sources]\n[packages]\n"
)


def test_toolchain_version_prints_and_exits_zero(tmp_path, capsys):
    cfg = tmp_path / "config.toml"
    cfg.write_text(_CONFIG)

    rc = cli.main(["--config", str(cfg), "--toolchain-version"])

    assert rc == 0
    assert capsys.readouterr().out.strip() == "42"


def test_dbtbuilder_error_returns_exit_code_one(monkeypatch, tmp_path):
    cfg = tmp_path / "config.toml"
    cfg.write_text(_CONFIG)

    def boom(*args, **kwargs):
        raise DbtBuilderError("boom")

    monkeypatch.setattr(cli, "run_build", boom)

    rc = cli.main(["--config", str(cfg)])

    assert rc == 1
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m pytest tests/test_cli.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'dbtbuilder.cli'`.

- [ ] **Step 3: Create `src/dbtbuilder/cli.py`**

```python
"""Command-line entry point — the only place that decides the process exit code."""

import argparse
from pathlib import Path

from rich import print as rich_print

from . import __version__
from .config import load_config
from .errors import DbtBuilderError
from .orchestrate import run_build
from .paths import BuildPaths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dbtbuilder",
        description="Fetch, verify, and package the DBT toolchain toolpacks.",
    )
    parser.add_argument("--config", type=Path, default=Path("config.toml"))
    parser.add_argument("--root", type=Path, default=None)
    parser.add_argument(
        "--platform",
        action="append",
        dest="platforms",
        choices=["linux", "darwin", "win32"],
        help="restrict the build to one or more platforms (repeatable)",
    )
    parser.add_argument(
        "--arch",
        action="append",
        dest="arches",
        help="restrict the build to one or more arches (repeatable)",
    )
    parser.add_argument(
        "--force", action="store_true", help="re-extract even if staging exists"
    )
    parser.add_argument(
        "--only",
        choices=["download", "extract", "wheels", "package"],
        help="run a single build phase",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--version", action="version", version=f"dbtbuilder {__version__}")
    parser.add_argument(
        "--toolchain-version",
        action="store_true",
        help="print the config.toml toolchain version and exit",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        config = load_config(args.config)
        if args.toolchain_version:
            print(config.version)
            return 0
        paths = BuildPaths.from_root(args.root)
        run_build(
            config,
            paths,
            platforms=args.platforms,
            arches=args.arches,
            force=args.force,
            only=args.only,
        )
    except DbtBuilderError as e:
        rich_print(f"[red bold]Error:[/red bold] {e}")
        return 1
    print("=^._.^= DONE =^._.^=")
    return 0
```

- [ ] **Step 4: Create `src/dbtbuilder/__main__.py`**

```python
"""Enable `python -m dbtbuilder`."""

import sys

from .cli import main

if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 5: Run the test and smoke-check both invocations**

Run:
```bash
python -m pytest tests/test_cli.py -v
python -m dbtbuilder --help
python -m dbtbuilder --toolchain-version
dbtbuilder --toolchain-version
```
Expected: tests PASS; `--help` prints the usage; both `--toolchain-version` calls print `25` (the current `config.toml` version). If `dbtbuilder` is not found, re-run `pip install -e ".[dev]"` (Task 1) to register the console script.

- [ ] **Step 6: Run the whole suite**

Run: `python -m pytest -v`
Expected: every test across all modules PASS.

- [ ] **Step 7: Commit**

```bash
git add src/dbtbuilder/cli.py src/dbtbuilder/__main__.py tests/test_cli.py
git commit -m "Add dbtbuilder CLI entry point"
```

---

### Task 12: Migrate CI, Docker sim, and packaging; remove the monolith

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `actions-support/dist-build/prepare.sh`
- Modify: `actions-support/simulate_dist_build.sh`
- Delete: `dbtbuilder.py`, `version.py`, `requirements.txt`

**Interfaces:**
- Consumes: the `dbtbuilder` console script and `dbtbuilder --toolchain-version` from Task 11; `pip install .` metadata from `pyproject.toml` (Task 1).
- Produces: a green CI pipeline that installs the package, runs `pytest`, builds via `dbtbuilder`, and reads the toolchain version via `dbtbuilder --toolchain-version`.

- [ ] **Step 1: Update `.github/workflows/release.yml`**

Replace the "Install python packages" step:

```yaml
      - name: Install python packages
        run: pip3 install -r requirements.txt
```

with an install-plus-test pair:

```yaml
      - name: Install dbtbuilder
        run: pip3 install ".[dev]"
      - name: Run unit tests
        run: python3 -m pytest
```

Replace the build step:

```yaml
      - name: Run build
        run: python3 ./dbtbuilder.py
```

with:

```yaml
      - name: Run build
        run: dbtbuilder
```

In the "Set up environment for Docker build" step, replace the version line:

```yaml
          echo "version=$(python3 version.py)" >> "$GITHUB_OUTPUT"
```

with:

```yaml
          echo "version=$(dbtbuilder --toolchain-version)" >> "$GITHUB_OUTPUT"
```

- [ ] **Step 2: Trim `actions-support/dist-build/prepare.sh`**

Replace the `apt-get install` block:

```bash
apt-get install -y \
  curl \
  perl \
  zip \
  python3 \
  python3-pip \
  python3-tqdm \
  python3-rich \
  python3-requests
```

with (drop the three now-pip-provided libs; add `python3-venv` so the sim can build an isolated env):

```bash
apt-get install -y \
  curl \
  perl \
  zip \
  python3 \
  python3-pip \
  python3-venv
```

- [ ] **Step 3: Update `actions-support/simulate_dist_build.sh` to install and run the package**

Replace the final `docker run` invocation:

```bash
docker run --rm -it \
  --user=$(id --user):$(id --group) \
  -v "$(pwd):$(pwd)" \
  --workdir "$(pwd)" \
  --entrypoint "$(pwd)/dbtbuilder.py" \
  dbt-builder:latest
```

with a venv install of the mounted package, then run the console script:

```bash
docker run --rm -it \
  --user=$(id --user):$(id --group) \
  --env HOME=/tmp \
  -v "$(pwd):$(pwd)" \
  --workdir "$(pwd)" \
  --entrypoint bash \
  dbt-builder:latest \
  -c 'python3 -m venv /tmp/dbt-venv && /tmp/dbt-venv/bin/pip install --quiet . && /tmp/dbt-venv/bin/dbtbuilder'
```

- [ ] **Step 4: Delete the monolith and its satellites**

```bash
git rm dbtbuilder.py version.py requirements.txt
```

- [ ] **Step 5: Verify nothing still references the removed files**

Run:
```bash
grep -rn --exclude-dir=.git --exclude-dir=docs -e "dbtbuilder\.py" -e "version\.py" -e "requirements\.txt" . || echo "no stale references"
```
Expected: `no stale references` (matches only inside `docs/` history are acceptable and excluded). If anything else matches, fix that caller before continuing.

- [ ] **Step 6: Final local verification**

Run:
```bash
python -m pytest -v
dbtbuilder --toolchain-version
python -c "from pathlib import Path; from dbtbuilder.config import load_config; load_config(Path('config.toml')).build_targets(); print('config OK')"
```
Expected: full suite PASS; `25` printed; `config OK` printed.

Heavier end-to-end (optional locally; otherwise CI covers it): `./actions-support/simulate_dist_build.sh` produces `dist/dbt-toolchain-25-*.tar.gz` (+ `.md5`/`.sha256`) identical in layout to a pre-refactor build. This downloads every toolchain (~hundreds of MB) and is slow — deferring to the CI run on push is acceptable.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/release.yml actions-support/dist-build/prepare.sh actions-support/simulate_dist_build.sh
git commit -m "Migrate CI and Docker sim to the dbtbuilder package; remove monolith"
```

---

## Notes for the implementer

- **Byte-for-byte parity is the real acceptance test.** The unit tests prove behavior in isolation, but the decisive check is that a full build produces the same archive layout and hash-file format as before. Preserve every string in the Global Constraints exactly. If you must change output, stop and flag it.
- **Fail-fast is intentional and may surface a latent bug.** The first CI run after this change can fail where the old code silently limped past a bad extraction or checksum. That is the fix working, not a regression in this plan — investigate the underlying toolchain issue.
- **`--default`/`set-executable`/`.exe` paths** exercise the raw-binary branch (clang-format, rustup-init). Tasks 6–7 cover the exec-bit on both the cache and staged copies; don't drop either.
- **`config/*.include` files** are optional and absent from the repo today; the include-filter branch is only taken when such a file exists. The tests fabricate one to cover it.
- **Ruff** is already used in this repo (`.ruff_cache`, strict Pylance in `.vscode`). Run `ruff check src tests` before each commit if available; the code here is written to line-length 100.
