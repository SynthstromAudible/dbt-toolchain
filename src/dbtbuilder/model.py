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
