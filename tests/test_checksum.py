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
