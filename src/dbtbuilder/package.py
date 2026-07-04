"""Compress each staged toolchain into a dist archive with hash sidecars."""

import hashlib
import tarfile
import zipfile
from pathlib import Path

from tqdm.rich import tqdm

from .paths import BuildPaths


def create_tar_gz(src_dir: Path, dest_file: Path) -> None:
    with tarfile.open(dest_file, "w:gz", compresslevel=6) as tar:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                tar.add(
                    file, arcname=file.relative_to(src_dir.parent), recursive=False
                )
                pbar.update(1)
                pbar.refresh()


def create_zip(src_dir: Path, dest_file: Path) -> None:
    with zipfile.ZipFile(dest_file, "w", zipfile.ZIP_DEFLATED) as zipf:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                zipf.write(file, arcname=file.relative_to(src_dir.parent))
                pbar.update(1)
                pbar.refresh()


def _write_hash(archive: Path, algo: str) -> None:
    with open(archive, "rb", buffering=0) as f:
        digest = hashlib.file_digest(f, algo).hexdigest()
    (archive.parent / f"{archive.name}.{algo}").write_text(digest)


def package_dist(version: int, platform: str, arch: str, paths: BuildPaths) -> None:
    staging = paths.staging_dir(platform, arch)
    if not staging.is_dir():
        return

    (staging / "VERSION").write_text(f"{version}\n")

    name = f"dbt-toolchain-{version}-{platform}-{arch}"
    if platform == "win32":
        archive = paths.dist / f"{name}.zip"
        create_zip(staging, archive)
    else:
        archive = paths.dist / f"{name}.tar.gz"
        create_tar_gz(staging, archive)

    _write_hash(archive, "md5")
    _write_hash(archive, "sha256")
