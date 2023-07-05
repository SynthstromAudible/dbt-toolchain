#!/usr/bin/env bash
#
# Simulate the Github Actions buildx build for the containers locally
set -xeuo pipefail

cd $(dirname $0)

# Assume that the dist step has already been run, and copy those file here so
# they're available for the buildx build context.
mkdir -p ./ci-image/dist
cp ../dist/dbt-toolchain-*-linux*.tar.gz ./ci-image/dist/

# Run the build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t deluge-ci-image:latest \
  -f ./ci-image/Dockerfile \
  --build-arg DBT_VERSION=$(cat ../VERSION) \
  --build-arg DELUGE_SRC_BRANCH=feature/dbt-e2-toolchain-changes \
  ./ci-image
