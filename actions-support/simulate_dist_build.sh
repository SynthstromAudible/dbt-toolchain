#!/usr/bin/env bash
#
# Simulate the Github Actions environment for the dist packaging locally using
# a Docker container
set -xeuo pipefail

cd $(dirname $0)

# we send only the actions-support directory because the simulation
# environment doesn't need whatever packages we've downloaded from prior
# runs.
docker build -t dbt-builder:latest -f ./dist-build/Dockerfile.sim ./dist-build

cd ../

docker run --rm -it \
  --user=$(id --user):$(id --group) \
  -v "$(pwd):$(pwd)" \
  --workdir "$(pwd)" \
  --entrypoint "$(pwd)/dbtbuilder.py" \
  dbt-builder:latest
