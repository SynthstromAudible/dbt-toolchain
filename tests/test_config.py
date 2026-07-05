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


def test_source_parses_bundle_subdir():
    raw = {
        **RAW,
        "sources": {
            **RAW["sources"],
            "cmake-macos": {
                "url": "http://c/cmake-{version}-macos-universal.{ext}",
                "ext": {"default": "tar.gz"},
                "bundle_subdir": "CMake.app/Contents",
            },
        },
    }
    cfg = parse_config(raw)
    assert cfg.sources["cmake-macos"].bundle_subdir == "CMake.app/Contents"
    # Sources without the key default to None.
    assert cfg.sources["xpack"].bundle_subdir is None


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
