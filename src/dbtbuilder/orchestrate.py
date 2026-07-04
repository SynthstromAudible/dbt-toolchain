"""Drive the download -> extract -> wheels -> package pipeline."""

import shutil

from rich import print as rich_print

from . import download, extract, package, wheels
from .model import Config
from .paths import BuildPaths

_WHEEL_LIBS = ("certifi", "ansi", "setuptools==75.8.0")


def run_build(
    config: Config,
    paths: BuildPaths,
    *,
    platforms: list[str] | None = None,
    arches: list[str] | None = None,
    force: bool = False,
    only: str | None = None,
) -> None:
    targets = config.build_targets()
    pairs = config.platform_arch_pairs()
    if platforms:
        targets = [t for t in targets if t.platform in platforms]
        pairs = [(p, a) for p, a in pairs if p in platforms]
    if arches:
        targets = [t for t in targets if t.arch in arches]
        pairs = [(p, a) for p, a in pairs if a in arches]

    paths.staging.mkdir(exist_ok=True)

    if only in (None, "download"):
        rich_print(r"[bold dim]\[1/3][/bold dim] Downloading...")
        for target in targets:
            download.download_target(target, paths)

    if only in (None, "extract"):
        rich_print(r"[bold dim]\[2/3][/bold dim] Extracting...")
        for target in targets:
            extract.extract_target(target, paths, force_reextract=force)

    if only in (None, "wheels"):
        for lib in _WHEEL_LIBS:
            wheels.add_python_lib(lib, pairs, paths)

    if only in (None, "package"):
        if paths.dist.exists():
            shutil.rmtree(paths.dist)
        paths.dist.mkdir()
        rich_print(r"[bold dim]\[3/3][/bold dim] Compressing toolpacks...")
        for platform, arch in pairs:
            package.package_dist(config.version, platform, arch, paths)
