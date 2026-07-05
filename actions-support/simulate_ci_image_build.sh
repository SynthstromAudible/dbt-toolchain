#!/usr/bin/env bash
#
# Simulate the Github Actions buildx build for the containers locally
set -xeuo pipefail

cd $(dirname $0)

# Assume that the dist step has already been run, and copy those file here so
# they're available for the buildx build context.
mkdir -p ./ci-image/dist
rsync -cv ../dist/dbt-toolchain-*-linux*.tar.gz ./ci-image/dist/

# Read the toolchain version straight from config.toml (stdlib only; no install).
DBT_VERSION=$(python3 -c "import tomllib; print(tomllib.load(open('../config.toml','rb'))['version'])")

# Run the build
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t deluge-ci-image:v${DBT_VERSION} \
  -f ./ci-image/Dockerfile \
  --build-arg DBT_VERSION=${DBT_VERSION} \
  --build-arg $(grep "^ARG DELUGE_SRC_ORG=" ./ci-image/Dockerfile | sed 's_ARG __g') \
  --build-arg $(grep "^ARG DELUGE_SRC_BRANCH=" ./ci-image/Dockerfile | sed 's_ARG __g') \
  ./ci-image
