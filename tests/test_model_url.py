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
