#!/usr/bin/env python3
import tomllib

with open("config.toml", "rb") as f:
    print(tomllib.load(f)['version'])
