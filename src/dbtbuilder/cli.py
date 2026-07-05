"""Command-line entry point — the only place that decides the process exit code."""

import argparse
from pathlib import Path

from rich import print as rich_print

from . import __version__
from .config import load_config
from .errors import DbtBuilderError
from .orchestrate import run_build
from .paths import BuildPaths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dbtbuilder",
        description="Fetch, verify, and package the DBT toolchain toolpacks.",
    )
    parser.add_argument("--config", type=Path, default=Path("config.toml"))
    parser.add_argument("--root", type=Path, default=None)
    parser.add_argument(
        "--platform",
        action="append",
        dest="platforms",
        choices=["linux", "darwin", "win32"],
        help="restrict the build to one or more platforms (repeatable)",
    )
    parser.add_argument(
        "--arch",
        action="append",
        dest="arches",
        help="restrict the build to one or more arches (repeatable)",
    )
    parser.add_argument("--force", action="store_true", help="re-extract even if staging exists")
    parser.add_argument(
        "--only",
        choices=["download", "extract", "wheels", "package"],
        help="run a single build phase",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--version", action="version", version=f"dbtbuilder {__version__}")
    parser.add_argument(
        "--toolchain-version",
        action="store_true",
        help="print the config.toml toolchain version and exit",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        config = load_config(args.config)
        if args.toolchain_version:
            print(config.version)
            return 0
        paths = BuildPaths.from_root(args.root)
        run_build(
            config,
            paths,
            platforms=args.platforms,
            arches=args.arches,
            force=args.force,
            only=args.only,
        )
    except DbtBuilderError as e:
        rich_print(f"[red bold]Error:[/red bold] {e}")
        return 1
    print("=^._.^= DONE =^._.^=")
    return 0
