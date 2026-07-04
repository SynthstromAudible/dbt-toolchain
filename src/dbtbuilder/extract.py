"""Extract downloaded archives (or copy raw binaries) into staging."""

import os
import shutil
import tarfile
import zipfile
from pathlib import Path

from tqdm.rich import tqdm

from .errors import ExtractError
from .model import BuildTarget
from .paths import BuildPaths


def extract_target(
    target: BuildTarget, paths: BuildPaths, force_reextract: bool = False
) -> None:
    package = target.package
    platform, arch = target.platform, target.arch
    dest_path = paths.staging_dir(platform, arch) / package.name
    filepath = paths.cache / target.cache_filename()

    # Raw binary or bare file: copy it straight into staging.
    if not filepath.suffix or filepath.suffix == ".exe":
        dest_file = dest_path / (package.name + filepath.suffix)
        dest_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(filepath, dest_file)
        # copyfile drops permissions; re-apply the exec bit to the staged (packaged)
        # file when the package asks for it.
        if package.details.get("set-executable", False):
            os.chmod(dest_file, 0o755)
        return

    # Archive: extract (optionally filtered) then flatten the single top dir.
    source = package.source
    ext = source.ext_map.get(platform) or source.ext_map["default"]
    include_file = paths.root / "config" / f"{platform}-{arch}-{package.name}.include"

    extractor = unzip_archive if ext == "zip" else untar_archive

    if force_reextract and dest_path.exists():
        shutil.rmtree(dest_path)

    if force_reextract or not dest_path.exists():
        extractor(filepath, dest_path, include_file)
        shift_subdir_up(package.name, dest_path.parent)


def shift_subdir_up(parent_dir: str, dest_path: Path) -> None:
    subdir_path = dest_path / parent_dir

    if len(list(subdir_path.iterdir())) < 2:
        subdir = next(subdir_path.iterdir()).name
        wrong_subdir_path = subdir_path.rename(dest_path / f"{parent_dir}.wrong")
        (wrong_subdir_path / subdir).rename(subdir_path)
        wrong_subdir_path.rmdir()


def untar_archive(tar_file: Path, dest_dir: Path, include_list: Path) -> None:
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    try:
        with tarfile.open(tar_file, "r") as tar:
            members = tar.getmembers()
            if include_list.is_file():
                root_dir = os.path.commonprefix(tar.getnames())
                with open(include_list) as f:
                    includes = [f"{root_dir}/{line.strip()}" for line in f]
                members = [m for m in members if m.name in includes]

            with tqdm(total=len(members), desc=tar_file.name, unit="files") as pbar:
                for member in members:
                    tar.extract(member, path=dest_dir, filter="data")
                    pbar.update(1)
                    pbar.refresh()
                pbar.refresh()
    except (tarfile.TarError, OSError) as e:
        raise ExtractError(f"failed to extract {tar_file.name}: {e}") from e


def unzip_archive(zip_file: Path, dest_dir: Path, include_list: Path) -> None:
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    try:
        with zipfile.ZipFile(zip_file, "r") as zip_ref:
            zip_includes: list[str] = []
            if include_list.is_file():
                root_dir = os.path.commonprefix(zip_ref.namelist())
                with open(include_list) as f:
                    zip_includes = [f"{root_dir}{line.strip()}" for line in f]

            total = len(zip_includes) if zip_includes else len(zip_ref.infolist())
            with tqdm(total=total, desc=zip_file.name, unit="files") as pbar:
                for info in zip_ref.infolist():
                    if not zip_includes or info.filename in zip_includes:
                        zip_ref.extract(info, dest_dir)
                        pbar.update(1)
                        pbar.refresh()
                pbar.refresh()
    except (zipfile.BadZipFile, OSError) as e:
        raise ExtractError(f"failed to extract {zip_file.name}: {e}") from e
