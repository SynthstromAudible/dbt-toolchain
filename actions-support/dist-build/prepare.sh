#!/usr/bin/env bash

set -xeuo pipefail

if [ -n "${IN_DOCKER_EMULATION+x}" ]; then
    apt-get update
    apt-get upgrade -y
fi
# perl provides OSX compatible "shasum"
# zip is required for Windows packaging
apt-get install -y curl perl zip
