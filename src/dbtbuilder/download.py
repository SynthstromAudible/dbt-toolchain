"""Fetch a single build target into the cache, verifying its checksum."""

import os

from . import checksum, http
from .model import BuildTarget
from .paths import BuildPaths


def download_target(target: BuildTarget, paths: BuildPaths) -> None:
    source = target.package.source
    url = target.format_url()

    checksum_url = None
    if source.checksum_url:
        checksum_url = source.checksum_url.format(
            url=url,
            url_no_ext=os.path.splitext(url)[0],
            **target.package.details,
        )

    filepath = paths.cache / target.cache_filename()

    if filepath.is_file() and checksum_url:
        # Cached and verifiable: confirm and skip the re-download.
        checksum.verify_remote(filepath, source.checksum_type, checksum_url, os.path.basename(url))
        return

    http.download_file(url, filepath)
    if checksum_url:
        checksum.verify_remote(filepath, source.checksum_type, checksum_url, os.path.basename(url))

    if target.package.details.get("set-executable", False):
        os.chmod(filepath, 0o755)
