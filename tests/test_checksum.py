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


def test_verify_remote_selects_matching_line_from_combined_file(http_server):
    # A single checksum file listing many assets (Kitware CMake style).
    base, served = http_server
    payload = served / "payload.bin"
    payload.write_bytes(b"hello world")
    digest = hashlib.sha256(payload.read_bytes()).hexdigest()
    (served / "SHA-256.txt").write_text(
        f"deadbeef  other-asset-a.tar.gz\n{digest}  payload.bin\ncafef00d  other-asset-b.zip\n"
    )

    # Should not raise: the line for payload.bin is selected, not the first line.
    checksum.verify_remote(payload, "sha256", f"{base}/SHA-256.txt", asset_name="payload.bin")


def test_verify_remote_rejects_when_named_asset_absent(http_server):
    base, served = http_server
    payload = served / "payload.bin"
    payload.write_bytes(b"hello world")
    digest = hashlib.sha256(payload.read_bytes()).hexdigest()
    # A multi-entry manifest that lists other assets but not payload.bin; must
    # fail loudly rather than latch onto some other line's digest. The first
    # line's digest even matches, to prove selection is by name, not position.
    (served / "SHA-256.txt").write_text(
        f"{digest}  some-other-asset.tar.gz\ncafef00d  yet-another-asset.zip\n"
    )

    with pytest.raises(ChecksumMismatch):
        checksum.verify_remote(payload, "sha256", f"{base}/SHA-256.txt", asset_name="payload.bin")
