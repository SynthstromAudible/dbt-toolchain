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


def test_download_target_resolves_versioned_combined_checksum(http_server, tmp_path):
    # checksum_url references {version} and points at a combined manifest that
    # lists several assets (Kitware CMake style).
    base, served = http_server
    payload = served / "tool-9.9-linux.bin"
    payload.write_bytes(b"combined-checksum-bytes")
    digest = hashlib.sha256(payload.read_bytes()).hexdigest()
    (served / "tool-9.9-SHA.txt").write_text(
        f"deadbeef  tool-9.9-other.bin\n{digest}  tool-9.9-linux.bin\n"
    )

    src = Source(
        name="t",
        url=f"{base}/tool-{{version}}-linux.bin",
        checksum_type="sha256",
        checksum_url=f"{base}/tool-{{version}}-SHA.txt",
        ext_map={"default": ""},
    )
    pkg = Package("tool", "linux", {"version": "9.9", "source": "t"}, src)
    target = BuildTarget(pkg, "x86_64")

    paths = BuildPaths.from_root(tmp_path / "work")
    download.download_target(target, paths)

    cached = paths.cache / target.cache_filename()
    assert cached.is_file()
    assert cached.read_bytes() == b"combined-checksum-bytes"
