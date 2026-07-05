"""Digest computation and remote-checksum verification."""

import hashlib
import os
from pathlib import Path

from . import http
from .errors import ChecksumMismatch


def file_digest(path: Path, algo: str) -> str:
    with open(path, "rb", buffering=0) as f:
        return hashlib.file_digest(f, algo).hexdigest()


def verify_remote(
    path: Path, algo: str, checksum_url: str, asset_name: str | None = None
) -> None:
    text = http.fetch_text(checksum_url)
    expected = _expected_digest(text, asset_name)
    actual = file_digest(path, algo)
    if actual != expected:
        raise ChecksumMismatch(
            f"{algo.upper()} mismatch for {path.name}: "
            f"expected {expected}, got {actual}"
        )


def _expected_digest(text: str, asset_name: str | None) -> str:
    """Pick this asset's digest from a checksum file.

    Handles both per-asset files (a bare digest, or a single ``digest  name``
    line) and combined manifests that list many assets on one line each — as
    Kitware's ``cmake-<ver>-SHA-256.txt`` does. When the file names multiple
    assets and none is ``asset_name``, ours is genuinely absent, so fail loudly
    rather than latch onto an unrelated line's digest.
    """
    named = [parts for line in text.splitlines() if len(parts := line.split()) >= 2]
    if asset_name:
        for parts in named:
            if os.path.basename(parts[-1].lstrip("*")) == asset_name:
                return parts[0]
        if len(named) > 1:
            raise ChecksumMismatch(
                f"no checksum entry for {asset_name!r} in checksum file"
            )
    # Bare digest, or a single unambiguous entry: first whitespace-delimited token.
    return text.strip().split()[0]
