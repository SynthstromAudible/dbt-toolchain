"""Build and distribute pure-Python wheels into every toolchain's python/wheel."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from .errors import DbtBuilderError
from .paths import BuildPaths


def get_sysname_arch() -> tuple[str, str]:
    if sys.platform == "win32":
        return "win32", "x86_64"
    return os.uname().sysname.lower(), os.uname().machine.lower()


def add_python_lib(
    lib_name: str,
    platform_arch_pairs: list[tuple[str, str]],
    paths: BuildPaths,
) -> None:
    sysname, arch = get_sysname_arch()
    this_path = paths.staging_dir(sysname, arch)

    if sysname == "win32":
        py_bin = this_path / "python/python.exe"
    else:
        py_bin = this_path / "python/bin/python3"

    wheel_dir = this_path / "python/wheel"
    wheel_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
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
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        detail = e.output.decode(errors="replace") if e.output else ""
        raise DbtBuilderError(f"pip wheel failed for '{lib_name}': {detail}") from e
    print(output.decode())

    wheel_files = [
        Path(line.strip().decode().split()[-1])
        for line in output.splitlines()
        if line.strip().decode().endswith(".whl")
    ]

    for os_label, os_arch in platform_arch_pairs:
        target_path = paths.staging_dir(os_label, os_arch)
        if target_path != this_path:
            target_wheel = target_path / "python/wheel"
            target_wheel.mkdir(parents=True, exist_ok=True)
            for wheel in wheel_files:
                shutil.copy(wheel, target_wheel / wheel.name)
