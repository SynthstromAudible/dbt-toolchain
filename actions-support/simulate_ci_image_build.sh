#!/usr/bin/env bash
#
# Simulate the Github Actions buildx build for the containers locally
set -xeuo pipefail

cd $(dirname $0)

# Assume that the dist step has already been run, and copy those file here so
# they're available for the buildx build context.
mkdir -p ./ci-image/dist
rsync -cv ../dist/dbt-toolchain-*-linux*.tar.gz ./ci-image/dist/

# Run the build
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t deluge-ci-image:v$(python3 ../version.py) \
  -f ./ci-image/Dockerfile \
  --build-arg DBT_VERSION=$(python3 ../version.py) \
  --build-arg $(grep ./ci-image/Dockerfile "^ARG DELUGE_SRC_ORG=" | sed 's_ARG __g') \
  --build-arg $(grep ./ci-image/Dockerfile "^ARG DELUGE_SRC_COMMIT=" | sed 's_ARG __g')  \
  ./ci-image
