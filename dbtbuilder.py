#!/usr/bin/env python3

# Script to collect all the necessary elements for use in building
# DelugeFirmware source code and modify them appropriately.

import hashlib
import os
import shutil
import subprocess
import sys
import tarfile
import tomllib
import urllib.request
import warnings
import zipfile
from pathlib import Path
from typing import Any

# External libraries
from rich import print as rich_print
from tqdm.rich import tqdm
from tqdm import TqdmExperimentalWarning

warnings.filterwarnings("ignore", category=TqdmExperimentalWarning)


ROOT_DIR = Path().resolve()
DIST_PATH = ROOT_DIR / "dist"
STAGING_PATH = ROOT_DIR / "staging"
CACHE_PATH = ROOT_DIR / "cache"


class Source:
    """"""

    def __init__(
        self,
        name: str,
        url: str,
        checksum_type: str,
        checksum_url: str,
        arch_map: dict[str, str] = {},
        ext_map: dict[str, str] = {},
        platform_map: dict[str, str] = {},
    ):
        self.name = name
        self.url = url
        self.checksum_type = checksum_type
        self.checksum_url = checksum_url
        self.arch_map = arch_map
        self.ext_map = ext_map
        self.platform_map = platform_map


class Package:
    """"""

    def __init__(
        self,
        name: str,
        platform: str,
        details: dict[str, str],
        sources: dict[str, Source],
    ):
        """"""
        self.name = name
        self.platform = platform
        self.details = details
        self.source = self._get_source(sources)

    def __repr__(self):
        return f"Package(name='{self.name}', platform='{self.platform}', details='{self.details}')"

    def _get_source(self, sources: dict[str, Source]) -> Source:
        source_key = self.details["source"]
        if type(source_key) == dict:  # type: ignore
            return sources[source_key[self.platform]]
        else:
            return sources[source_key]

    def format_url(self, arch: str) -> str:
        source = self.source
        ext = source.ext_map.get(self.platform) or source.ext_map["default"]
        platform = source.platform_map.get(self.platform) or self.platform
        return source.url.format(
            platform=platform,
            arch=source.arch_map.get(arch) or arch,
            name=self.name,
            ext=ext,
            **self.details,
        )


def checksum_remote(filepath: Path, checksum_type: str, checksum_url: str):
    with urllib.request.urlopen(checksum_url) as response:
        hash = response.read().decode("ascii").strip().split()[0]
        with open(filepath, "rb", buffering=0) as f:
            actual_hash = hashlib.file_digest(f, checksum_type).hexdigest()  # type: ignore
            return actual_hash == hash


def download_package(package: Package, platform: str, arch: str) -> None:
    url = package.format_url(arch)
    checksum_type = package.source.checksum_type
    checksum_url = package.source.checksum_url.format(
        url=url, url_no_ext=os.path.splitext(url)[0]
    )
    filename = os.path.basename(url)
    filepath = CACHE_PATH / filename

    if filepath.is_file():
        print(f"Found {filename}, checking {checksum_type.upper()}...", end="")
        if checksum_url:
            if checksum_remote(filepath, checksum_type, checksum_url):
                rich_print("[green bold]VALID")
                return
            else:
                rich_print("[red bold]Error![/red bold]")
                sys.exit(-1)

    download_file(url, filepath)
    if checksum_url and not checksum_remote(filepath, checksum_type, checksum_url):
        rich_print(
            f"[red bold]Error![/red bold] ${checksum_type.upper()} signature did not match for file: {filepath.name}"
        )
        sys.exit(-1)


def extract_package(
    package: Package, platform: str, arch: str, force_reextract: bool = False
):
    dest_path = STAGING_PATH / f"{platform}-{arch}" / package.name
    url = package.format_url(arch)
    filename = os.path.basename(url)
    filepath = CACHE_PATH / filename

    if not filepath.suffix or filepath.suffix is ".exe":
        dest_path = dest_path / "bin" / filename
        os.makedirs(dest_path, exist_ok=True)
        shutil.copyfile(filepath, dest_path)
    else:
        # Assume an archive if it has a
        ext = package.source.ext_map.get(platform) or package.source.ext_map["default"]
        include_file = ROOT_DIR / "config" / f"{platform}-{arch}-{package.name}.include"

        # print(f"Extracting {os}-{arch} {name}:")
        if ext == "zip":
            extractor = unzip_archive
        else:
            extractor = untar_archive

        if force_reextract and dest_path.exists():
            shutil.rmtree(dest_path)

        if force_reextract or not dest_path.exists():
            extractor(filepath, dest_path, include_file)
            shift_subdir_up(package.name, dest_path)


# from https://stackoverflow.com/a/63831344
def download_file(url: str, filename: Path):
    import requests

    filename.parent.mkdir(parents=True, exist_ok=True)
    with requests.get(url, stream=True, allow_redirects=True) as r:
        if r.status_code != 200:
            r.raise_for_status()  # Will only raise for 4xx codes, so...
            raise RuntimeError(f"Request to {url} returned status code {r.status_code}")
        file_size = int(r.headers.get("Content-Length", 0))
        block_size = 1024

        with tqdm(
            total=file_size,
            unit="B",
            unit_scale=True,
            miniters=0.01,
            desc=filename.name,
        ) as pbar:
            with filename.open("wb") as file:
                for data in r.iter_content(block_size):
                    file.write(data)
                    pbar.update(len(data))
                    pbar.refresh()
            pbar.refresh()

    return filename


def create_tar_gz_with_progress(src_dir: Path, dest_file: Path):
    with tarfile.open(dest_file, "w:gz", compresslevel=6) as tar:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                tar.add(file, arcname=file.relative_to(src_dir.parent), recursive=False)
                pbar.update(1)
                pbar.refresh()


def create_zip_with_progress(src_dir: Path, dest_file: Path):
    with zipfile.ZipFile(dest_file, "w", zipfile.ZIP_DEFLATED) as zipf:
        files = list(src_dir.rglob("*"))
        with tqdm(
            total=len(files), desc=f"Compressing {dest_file.name}", unit="files"
        ) as pbar:
            for file in files:
                zipf.write(file, arcname=file.relative_to(src_dir.parent))
                pbar.update(1)
                pbar.refresh()


def shift_subdir_up(parent_dir: str, dest_path: Path):
    subdir_path = dest_path / parent_dir

    if len(list(subdir_path.iterdir())) < 2:
        subdir = next(subdir_path.iterdir()).name
        wrong_subdir_path = subdir_path.rename(dest_path / f"{parent_dir}.wrong")
        (wrong_subdir_path / f"{subdir}").rename(subdir_path)
        wrong_subdir_path.rmdir()


def untar_archive(
    tar_file: Path,
    dest_dir: Path,
    include_list: Path,
):
    try:
        # Clear existing destination directory
        if dest_dir.exists():
            shutil.rmtree(dest_dir)

        # Create destination directory
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Extract files from tar archive with progress bar
        with tarfile.open(tar_file, "r") as tar:
            members = tar.getmembers()
            if Path(include_list).is_file():
                root_dir = os.path.commonprefix(tar.getnames())
                includes = [
                    f"{root_dir}/{line.strip()}" for line in open(include_list, "r")
                ]
                members = [member for member in members if member.name in includes]

            # tar.extractall(path=dest_dir, members=members)
            with tqdm(total=len(members), desc=tar_file.name, unit="files") as pbar:
                for member in members:
                    tar.extract(member, path=dest_dir, filter="data")
                    pbar.update(1)
                    pbar.refresh()
                pbar.refresh()

    except Exception as e:
        print(f"Error: {e}")


def unzip_archive(
    zip_file: Path,
    dest_dir: Path,
    include_list: Path,
):
    try:
        # Clear existing destination directory
        if dest_dir.exists():
            shutil.rmtree(dest_dir)

        # Create destination directory
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Extract files from zip archive with progress bar
        with zipfile.ZipFile(zip_file, "r") as zip_ref:
            zip_includes = []
            if Path(include_list).is_file():
                root_dir = os.path.commonprefix(zip_ref.namelist())
                zip_includes = [
                    f"{root_dir}{line.strip()}" for line in open(include_list, "r")
                ]

            total_files = len(zip_includes) if zip_includes else len(zip_ref.infolist())

            with tqdm(total=total_files, desc=zip_file.name, unit="files") as pbar:
                for file_info in zip_ref.infolist():
                    if not zip_includes or file_info.filename in zip_includes:
                        zip_ref.extract(file_info, dest_dir)
                        pbar.update(1)
                        pbar.refresh()
                pbar.refresh()

    except Exception as e:
        print(f"Error: {e}")


def get_sysname_arch():
    if sys.platform == "win32":
        sysname = "win32"
        arch = "x86_64"
    else:
        sysname: str = os.uname().sysname.lower()
        arch: str = os.uname().machine.lower()
    return (sysname, arch)


def add_python_lib(lib_name: str, platform_arch_pairs: list[tuple[str, str]]):
    sysname, arch = get_sysname_arch()
    this_path = STAGING_PATH / f"{sysname}-{arch}"

    if sysname == "win32":
        py_bin = this_path / "python/python.exe"
    else:
        py_bin = this_path / "python/bin/python3"

    wheel_dir = this_path / "python/wheel"
    os.makedirs(wheel_dir, exist_ok=True)

    try:
        cmd: list[str] = [
            str(py_bin),
            "-m",
            "pip",
            "--disable-pip-version-check",
            "wheel",
            "--wheel-dir",
            str(wheel_dir),
            lib_name,
        ]
        print(f"Installing python lib '{lib_name}'")
        wheel_files = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        print(wheel_files.decode())
        wheel_files = [
            Path(line.strip().decode().split()[-1])
            for line in wheel_files.splitlines()
            if line.strip().decode().endswith(".whl")
        ]

        for os_label, os_arch in platform_arch_pairs:
            target_path = STAGING_PATH / f"{os_label}-{os_arch}"
            if target_path != this_path:
                target_wheel = target_path / "python/wheel"
                target_wheel.mkdir(parents=True, exist_ok=True)
                for wheel in wheel_files:
                    shutil.copy(wheel, target_wheel / wheel.name)

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")


def package_dist(config: dict[str, Any], platform: str, arch: str):
    dist_os_path = STAGING_PATH / f"{platform}-{arch}"

    if dist_os_path.is_dir():
        with open(dist_os_path / "VERSION", "w") as v_file:
            v_file.write(f"{config['version']}\n")

        dist_file = f"dbt-toolchain-{config['version']}-{platform}-{arch}"
        if platform == "win32":
            dist_file = f"{dist_file}.zip"
            create_zip_with_progress(dist_os_path, DIST_PATH / dist_file)

        else:
            dist_file = f"{dist_file}.tar.gz"
            create_tar_gz_with_progress(dist_os_path, DIST_PATH / dist_file)

        if dist_file != "":
            # Calculate MD5 and SHA256 hashes
            md5_hash = hashlib.md5()
            sha256_hash = hashlib.sha256()

            with open(DIST_PATH / dist_file, "rb", buffering=0) as f:
                md5_hash = hashlib.file_digest(f, "md5").hexdigest()  # type: ignore
                sha256_hash = hashlib.file_digest(f, "sha256").hexdigest()  # type: ignore

            # Generate MD5
            with open(DIST_PATH / f"{dist_file}.md5", "w") as md5_file:
                md5_file.write(md5_hash)

            # Generate SHA-256
            with open(DIST_PATH / f"{dist_file}.sha256", "w") as sha256_file:
                sha256_file.write(sha256_hash)


def main():
    sources: dict[str, Source] = {}
    packages: list[Package] = []

    with open(ROOT_DIR / "config.toml", "rb") as f:
        config = tomllib.load(f)

    platform_arch_pairs = [
        (name, arch)
        for (name, details) in config["platforms"].items()
        for arch in details["arch"]
    ]

    for name, details in config["sources"].items():
        sources[name] = Source(
            name,
            details["url"],
            details.get("checksum_type") or "sha256",
            details.get("checksum_url"),
            details.get("arch") or {},
            details.get("ext") or {},
            details.get("platform") or {},
        )

    for name, details in config["packages"].items():
        if "source" in details.keys():
            packages += [
                Package(name, platform, details, sources)
                for platform in config["platforms"].keys()
            ]
        else:
            for platform, info in details.items():
                if platform == "default":
                    packages += [
                        Package(name, platform, info, sources)
                        for platform in config["platforms"].keys()
                        if platform not in details.keys()
                    ]
                else:
                    packages += [Package(name, platform, info, sources)]

    # Location for all the files downloaded.
    STAGING_PATH.mkdir(exist_ok=True)

    # Fetch, verify, and extract all the required toolchain tools
    matrix = [
        (package, platform, arch)
        for package in packages
        for platform, arch in platform_arch_pairs
        if package.platform == platform
    ]

    rich_print(rf"[bold dim]\[1/3][/bold dim] Downloading...")
    for t in matrix:
        download_package(*t)

    rich_print(rf"[bold dim]\[2/3][/bold dim] Extracting...")
    for t in matrix:
        extract_package(*t)

    add_python_lib("certifi", platform_arch_pairs)
    add_python_lib("ansi", platform_arch_pairs)
    add_python_lib("setuptools==75.8.0", platform_arch_pairs)

    # DIST/PACKAGE
    if DIST_PATH.exists():
        shutil.rmtree(DIST_PATH)
    DIST_PATH.mkdir()

    rich_print(rf"[bold dim]\[3/3][/bold dim] Compressing toolpacks...")
    for platform, arch in platform_arch_pairs:
        package_dist(config, platform, arch)

    print("=^._.^= DONE =^._.^=")


if __name__ == "__main__":
    main()
