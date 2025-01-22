#!/usr/bin/env python3
import tomllib
from pathlib import Path

path = Path(__file__).parent / "config.toml"

with open(path, "rb") as f:
    print(tomllib.load(f)['version'])
