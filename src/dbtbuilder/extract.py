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
        if source.bundle_subdir:
            lift_bundle_subdir(dest_path, source.bundle_subdir)


def _load_include_patterns(include_list: Path) -> list[str]:
    """Read an include file: stripped lines, skipping blanks and ``#`` comments.

    Skipping blanks matters: an empty line would otherwise become a bare root
    prefix that keeps every member, silently defeating the filter.
    """
    with open(include_list) as f:
        return [s for line in f if (s := line.strip()) and not s.startswith("#")]


def _is_included(name: str, patterns: list[str]) -> bool:
    """True when ``name`` equals or is nested under an include pattern.

    Prefix matching (with a ``/`` boundary) lets a directory pattern keep its
    whole subtree — e.g. ``share`` keeps ``share/cmake-4.3/Modules/…`` — without
    enumerating every file, while ``share`` still won't match ``shareX``.
    """
    return any(name == p or name.startswith(p + "/") for p in patterns)


def lift_bundle_subdir(dest_path: Path, subdir: str) -> None:
    """Promote a nested subdir's contents up to the package root.

    Kitware's macOS cmake ships as an app bundle, so after the usual wrapper
    shift the payload sits under ``CMake.app/Contents`` rather than directly in
    the package dir. Moving every child of that subdir up together keeps
    siblings like ``bin`` and ``share`` adjacent, so cmake's ``../share`` module
    lookups still resolve. The now-empty wrapper is removed.
    """
    nested = dest_path / subdir
    for child in nested.iterdir():
        child.rename(dest_path / child.name)
    shutil.rmtree(dest_path / Path(subdir).parts[0])


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
                includes = [
                    f"{root_dir}/{s}" for s in _load_include_patterns(include_list)
                ]
                members = [m for m in members if _is_included(m.name, includes)]

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
                zip_includes = [
                    f"{root_dir}{s}" for s in _load_include_patterns(include_list)
                ]

            members = [
                info
                for info in zip_ref.infolist()
                if not zip_includes or _is_included(info.filename, zip_includes)
            ]
            with tqdm(total=len(members), desc=zip_file.name, unit="files") as pbar:
                for info in members:
                    zip_ref.extract(info, dest_dir)
                    pbar.update(1)
                    pbar.refresh()
                pbar.refresh()
    except (zipfile.BadZipFile, OSError) as e:
        raise ExtractError(f"failed to extract {zip_file.name}: {e}") from e
