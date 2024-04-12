#!/usr/bin/env python3

import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import zipfile
from typing import Dict, Optional, List
import os

from tqdm.auto import tqdm
import tomllib

import urllib.request

VERSION = open("VERSION").read().strip()

ROOT_DIR = Path().resolve()
DIST_PATH = ROOT_DIR / "dist"
STAGING_PATH = ROOT_DIR / "staging"


class Source:
    """"""

    def __init__(
        self,
        name: str,
        url: str,
        sha: str,
        arch_map: Dict[str, str] = {},
        ext_map: Dict[str, str] = {},
        platform_map: Dict[str, str] = {},
    ):
        self.name = name
        self.url = url
        self.sha = sha
        self.arch_map = arch_map
        self.ext_map = ext_map
        self.platform_map = platform_map


class Package:
    """"""

    def __init__(
        self,
        name: str,
        source: Source,
        details: Dict[str, str],
    ):
        """"""
        self.name = name
        self.source = source
        self.details = details

    def _format_url(self, platform: str, arch: str) -> str:
        ext = self.source.ext_map.get(platform) or self.source.ext_map["default"]
        platform = self.source.platform_map.get(platform) or platform
        return self.source.url.format(
            platform=platform,
            arch=self.source.arch_map.get(arch) or arch,
            name=self.name,
            ext=ext,
            **self.details,
        )

    def download(self, platform: str, arch: str) -> None:
        url = self._format_url(platform, arch)
        hash_url = self.source.sha.format(url=url)
        filename = os.path.basename(url)
        filepath = STAGING_PATH / filename

        if not filepath.is_file():
            print(f"Downloading {filename}:")
            dbtb_curl(url, filepath)

        print(f"Checking SHA256 signature of {filename}... ", end="")
        with urllib.request.urlopen(hash_url) as response:
            hash = response.read().decode("ascii").strip().split()[0]
            actual_hash = calc_sha256_file(filepath)
            if hash != actual_hash:
                print("INVALID")
            else:
                print("VALID")

    def extract(self, platform: str, arch: str, force_reextract: bool = False):
        url = self._format_url(platform, arch)
        filepath = STAGING_PATH / os.path.basename(url)
        dest_path = STAGING_PATH / f"{platform}-{arch}"
        ext = self.source.ext_map.get(platform) or self.source.ext_map["default"]
        include_file = ROOT_DIR / f"config/{platform}-{arch}-{self.name}.include"

        # print(f"Extracting {os}-{arch} {name}:")
        if ext == "zip":
            extractor = unzip_archive
        else:
            extractor = untar_archive

        decompress_path = dest_path / self.name
        if force_reextract and decompress_path.exists():
            shutil.rmtree(decompress_path)

        if force_reextract or not decompress_path.exists():
            extractor(filepath, decompress_path, include_file)
            shift_subdir_up(self.name, dest_path)


sources: Dict[str, Source] = {}
packages: List[Package] = []

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
        details["sha"],
        details.get("arch") or {},
        details.get("ext") or {},
        details.get("platform") or {},
    )

for source, package in config["packages"].items():
    for name, details in package.items():
        if type(details) is str:
            packages += [Package(name, sources[source], {"version": details})]
        else:
            packages += [Package(name, sources[source], details)]


def calc_sha256_file(filepath: Path, block_size: int = 2**20):
    with open(filepath, "rb", buffering=0) as f:
        return hashlib.file_digest(f, "sha256").hexdigest()  # type: ignore


def calc_md5_file(filepath: Path, block_size: int = 2**20):
    with open(filepath, "rb", buffering=0) as f:
        return hashlib.file_digest(f, "md5").hexdigest()  # type: ignore


# from https://stackoverflow.com/a/63831344
def dbtb_curl(url: str, filename: Path):
    import functools
    import shutil
    import requests

    r = requests.get(url, stream=True, allow_redirects=True)
    if r.status_code != 200:
        r.raise_for_status()  # Will only raise for 4xx codes, so...
        raise RuntimeError(f"Request to {url} returned status code {r.status_code}")
    file_size = int(r.headers.get("Content-Length", 0))

    filename.parent.mkdir(parents=True, exist_ok=True)

    desc = "(Unknown total file size)" if file_size == 0 else ""
    r.raw.read = functools.partial(
        r.raw.read, decode_content=True
    )  # Decompress if needed
    with tqdm.wrapattr(r.raw, "read", total=file_size, desc=desc, ascii=True) as r_raw:  # type: ignore
        with filename.open("wb") as f:
            shutil.copyfileobj(r_raw, f)

    return filename


def check_downloaded_file(file: Path):
    print(f"Checking if {file} exists..")

    if not file.is_file():
        print("no")
        return False
    print("yes")
    return True


def shift_subdir_up(parent_dir: str, dest_path: Path):
    subdir_path = dest_path / parent_dir

    if len(list(subdir_path.iterdir())) < 2:
        subdir = next(subdir_path.iterdir()).name
        subdir_path = subdir_path.rename(dest_path / f"{parent_dir}.wrong")
        (subdir_path / f"{subdir}").rename(dest_path / parent_dir)
        subdir_path.rmdir()


def untar_archive(
    tar_file: Path,
    dest_dir: Path,
    include_list: Path,
):
    print(f"Unpacking {tar_file} to '{dest_dir}':")

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
            with tqdm(total=len(members), ascii=True) as pbar:
                for member in members:
                    tar.extract(member, path=dest_dir)
                    pbar.update(1)

        print("done")

    except Exception as e:
        print(f"Error: {e}")


def unzip_archive(
    zip_file: Path,
    dest_dir: Path,
    include_list: Path,
):
    print(f"Unzipping {zip_file} to '{dest_dir}':")

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

            with tqdm(total=total_files, ascii=True) as pbar:
                for file_info in zip_ref.infolist():
                    if not zip_includes or file_info.filename in zip_includes:
                        zip_ref.extract(file_info, dest_dir)
                        pbar.update(1)

        print("done")

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


def add_python_lib(lib_name: str):
    sysname, arch = get_sysname_arch()
    this_path = STAGING_PATH / f"{sysname}-{arch}"

    if sysname == "win32":
        py_bin = this_path / "python/python.exe"
    else:
        py_bin = this_path / "python/bin/python3"

    wheel_dir = this_path / "python/wheel"
    os.makedirs(wheel_dir, exist_ok=True)

    print(f"Adding python lib: {lib_name}")

    try:
        wheel_files = subprocess.check_output(
            [py_bin, "-m", "pip", "wheel", "-w", wheel_dir, lib_name]
        )
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


def package_dist():
    # Clear the contents of the DIST_PATH directory
    for file in DIST_PATH.iterdir():
        if file.is_file():
            file.unlink()
        elif file.is_dir():
            shutil.rmtree(file)

    for platform, arch in platform_arch_pairs:
        dist_os_path = STAGING_PATH / f"{platform}-{arch}"
        print(f"Packaging {dist_os_path}")

        if dist_os_path.is_dir():
            shutil.copy(ROOT_DIR / "VERSION", dist_os_path / "VERSION")

            dist_file = f"dbt-toolchain-{VERSION}-{dist_os_path}"
            if platform == "darwin" or platform == "linux":
                shutil.make_archive(str(DIST_PATH / dist_file), "gztar", dist_os_path)
            elif platform == "win32":
                shutil.make_archive(str(DIST_PATH / dist_file), "zip", dist_os_path)

            if dist_file != "":
                # Calculate MD5 and SHA256 hashes
                md5_hash = hashlib.md5()
                sha256_hash = hashlib.sha256()

                with open(DIST_PATH / dist_file, "rb", buffering=0) as f:
                    md5_hash = hashlib.file_digest(f, "md5").hexdigest() # type: ignore
                    sha256_hash = hashlib.file_digest(f, "sha256").hexdigest() # type: ignore

                # Generate MD5
                with open(DIST_PATH / f"{dist_file}.md5", "w") as md5_file:
                    md5_file.write(md5_hash)

                # Generate SHA-256
                with open(DIST_PATH / f"{dist_file}.sha256", "w") as sha256_file:
                    sha256_file.write(sha256_hash)


# Location for all the files downloaded.
STAGING_PATH.mkdir(exist_ok=True)

# Fetch, verify, and extract all the required toolchain tools
for package in packages:
    for platform, arch in platform_arch_pairs:
        package.download(platform, arch)

for package in packages:
    for platform, arch in platform_arch_pairs:
        package.extract(platform, arch)

add_python_lib("certifi")
add_python_lib("ansi")
add_python_lib("setuptools==69.0.3")

# DIST/PACKAGE
DIST_PATH.mkdir(exist_ok=True)

# package_dist()
print("=^._.^= DONE =^._.^=")
