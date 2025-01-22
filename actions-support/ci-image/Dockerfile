# syntax=docker/dockerfile:1-labs
# Download and unpack the toolchain on the build host architecture
FROM --platform=$BUILDPLATFORM ubuntu:24.04 as toolchain-unpacker
ARG BUILDPLATFORM
ARG DBT_VERSION

# Install tools required to unpack the toolchain archive
RUN apt-get update && apt-get install -y curl parallel

# Use the local toolchain files
COPY ./dist/dbt-toolchain-$DBT_VERSION-linux-x86_64.tar.gz /dbt/toolchain/v${DBT_VERSION}/

# Unpack the toolchain in the unpack container
RUN <<LOAD_TOOLCHAIN bash
  set -ex
  mkdir -p /dbt/toolchain/v\${DBT_VERSION}
  cd /dbt/toolchain/v\${DBT_VERSION}
  targets="x86_64"
  for target_arch in \$targets; do
    DBT_TOOLCHAIN_TAR=dbt-toolchain-${DBT_VERSION}-linux-\${target_arch}.tar.gz

    # For local development (see COPY commands above) don't redownload
    # toolchains if they're already present
    if [ ! -e "\${DBT_TOOLCHAIN_TAR}" ]; then
      curl -LO ${TOOLCHAIN_URL}/v${DBT_VERSION}/\${DBT_TOOLCHAIN_TAR}
      sha256sum \${DBT_TOOLCHAIN_TAR} | grep "$DBT_TOOLCHAIN_SHA_\$target_arch"
    fi

    # Untar the toolchain and delete the tar file to reduce layer size
    tar xf \${DBT_TOOLCHAIN_TAR} 2> >(grep -v "tar: Ignoring unknown extended header keyword")
    rm \${DBT_TOOLCHAIN_TAR}
    # Make Python R+W by the build user
    find /dbt/toolchain/v\${DBT_VERSION}/linux-\$target_arch/python \
      -exec chown 1000:1000 {} \+ -exec chmod a+rw {} \+
  done
  # kinda stupid hack: move linux-x86_64 to linux-amd64 so we can do a COPY
  # --from below using the Docker TARGETARCH. We then move it back to the right position
  mv /dbt/toolchain/v\${DBT_VERSION}/linux-x86_64/ /dbt/toolchain/v\${DBT_VERSION}/linux-amd64
  ls /dbt/toolchain/v\${DBT_VERSION}
LOAD_TOOLCHAIN

# Configure user
RUN useradd -ms /bin/bash nonroot

# The build container
FROM ubuntu:24.04 AS builder
ARG DBT_VERSION
# top-of-tree as of 2024-04-11
ARG DELUGE_SRC_ORG=synthstromaudible
ARG DELUGE_SRC_COMMIT=2b653a948368ce114387c4200f1412be9e128d19
ARG TARGETARCH

# Install tools required by DBT
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --yes --no-install-recommends git curl ca-certificates

# Configure user
RUN useradd -ms /bin/bash nonroot

# Copy DBT from the unpack container
COPY --from=toolchain-unpacker /dbt/toolchain/v$DBT_VERSION/linux-$TARGETARCH/ /dbt/toolchain/v$DBT_VERSION/linux-$TARGETARCH/
RUN if [ "$TARGETARCH" = "amd64" ]; then mv /dbt/toolchain/v$DBT_VERSION/linux-amd64 /dbt/toolchain/v$DBT_VERSION/linux-x86_64; fi
ENV DBT_TOOLCHAIN_PATH=/dbt
ENV DELUGE_FW_ROOT=/build

# Smoke run, which both checks that the toolchain is working and installs the
# wheels for us so we don't need to ship those in the final image.
#
# We don't use the native git support for `ADD` because it caches in a very
# stupid way. This reinvents that particular wheel
# See https://stackoverflow.com/questions/36996046/how-to-prevent-dockerfile-caching-git-clone
RUN --mount=type=cache,target=/tmp/git_cache/ <<GIT_CHECKOUT bash
  set -ex
  git clone https://github.com/$DELUGE_SRC_ORG/DelugeFirmware.git /tmp/git_cache/DelugeFirmware || true
  cd /tmp/git_cache/DelugeFirmware/
  git fetch
  mkdir -p /build
  git checkout ${DELUGE_SRC_COMMIT}
  cp -r ./* ./.git/ /build/
GIT_CHECKOUT
RUN <<SMOKE_BUILD bash
  set -ex
  cd /build
  # We only actually build on amd64 because running the compiler under
  # emulation is extremely slow.
  case "$TARGETARCH" in
    amd64) ./dbt build ;;
    arm64) ./dbt configure ;;
    *)
      echo "Unsupported TARGETARCH" $TARGETARCH
      exit 1
      ;;
  esac
SMOKE_BUILD
RUN rm -rf /dbt/toolchain/linux-$TARGETARCH/python/wheel/*

#
# Build the final image, based on distroless
#
FROM ubuntu:latest as final
ARG TARGETARCH

# Make sure we have git, as it's needed at runtime
# libxml2 is required for fmt task
# doxygen required for docs
RUN apt-get update && apt-get install --yes --no-install-recommends git ca-certificates libxml2 doxygen curl && rm -rf /var/lib/apt/lists/*

# Insert the DBT itself
COPY --from=builder /dbt /dbt
RUN useradd -ms /bin/bash nonroot
ENV DBT_TOOLCHAIN_PATH=/dbt
USER nonroot

WORKDIR /src/
ENTRYPOINT ["/src/dbt"]
