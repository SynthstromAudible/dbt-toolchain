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
