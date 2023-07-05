#!/usr/bin/env bash
#
# Simulate the Github Actions environment locally using a Docker container
set -xeuo pipefail

# we send only the actions-support directory because the simulation
# environment doesn't need whatever packages we've downloaded from prior
# runs.
docker build -t dbt-builder:latest -f ./actions-support/Dockerfile.sim ./actions-support

docker run --rm -t \
  --user=$(id --user):$(id --group) \
  -v "$(pwd):$(pwd)" \
  --workdir "$(pwd)" \
  --entrypoint "$(pwd)/dbtbuilder.sh" \
  dbt-builder:latest
