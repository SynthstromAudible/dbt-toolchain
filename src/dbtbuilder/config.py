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
