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
