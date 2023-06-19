# Deluge Build Tool (DBT) Toolchain

The source repo for this is still a work-in-progress as it fetches from multiple sources to build each zip/tarball. Currently this is a manual process of downloading, extraction, renaming, and archiving, but it will be scripted in the coming days.

As of right now, Linux and Mac (darwin) are supported on either of arm64/aarch64 or x86_64 architectures. Windows is supported on x86_64 only.

These toolchains are installed and used by DBT in-place as "portable" or "standalone" style packages. The appropriate toolchain is installed based on which platform the scripts are run from so you should (once DBT is working) not have to download these independently.

## xpack arm-none-eabi-gcc

There are three officially supported toolchain versions for the Renesas RZ/A series in e<sup>2</sup> studio:
* 6-2017-q2-update
* 9-2019-q4-major
* 9-2020-q2-update

For DBT I've initially opted to include [12.2.1](https://xpack.github.io/blog/2023/02/05/arm-none-eabi-gcc-v12-2-1-1-2-released/) as this is the most up-to-date toolchain released by ARM. I am using the xpack version. It has been tested to be working in e<sup>2</sup> Studio in Windows with the official Windows installer version of [arm-none-eabi-gcc 12.2](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) by pointing it to this version toolchain. Officially, for the moment however, 9.2.1 remains the gold standard for Deluge testing. That does not mean developers cannot make use of 12.2.1, however.

* Windows x86 (32bit): https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2/xpack-arm-none-eabi-gcc-12.2.1-1.2-win32-x64.zip
* Mac (darwin) x86_64: https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2/xpack-arm-none-eabi-gcc-12.2.1-1.2-darwin-x64.tar.gz
* Mac (darwin) arm64: https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2/xpack-arm-none-eabi-gcc-12.2.1-1.2-darwin-arm64.tar.gz
* Linux x86_64: https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2/xpack-arm-none-eabi-gcc-12.2.1-1.2-linux-x64.tar.gz
* Linux arm64/aarch64: https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2/xpack-arm-none-eabi-gcc-12.2.1-1.2-linux-arm64.tar.gz

## xpack OpenOCD

In order to enable support for [DelugeProbe](https://github.com/litui/delugeprobe/) and other third-party debuggers, OpenOCD will need to be used. Here, I've opted for the [latest version from xpack-dev-tools](https://github.com/xpack-dev-tools/openocd-xpack/releases/tag/v0.12.0-1) (without installing xpack as there's little other reason to include node.js):

* Windows x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-win32-x64.zip
* Mac x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-darwin-x64.tar.gz
* Mac arm64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-darwin-arm64.tar.gz
* Linux x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-linux-x64.tar.gz
* Linux arm64/aarch64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-linux-arm64.tar.gz

## Python

Python comes via [Standalone Python](https://github.com/indygreg/python-build-standalone). Packages were chosen for simplicity and compatibility:

* Windows x64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-i686-pc-windows-msvc-static-install_only.tar.gz
* Mac (darwin) x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-x86_64-apple-darwin-install_only.tar.gz
* Mac (darwin) arm64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-aarch64-apple-darwin-install_only.tar.gz
* Linux x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-x86_64-unknown-linux-gnu-install_only.tar.gz
* Linux arm64/aarch64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-aarch64-unknown-linux-gnu-install_only.tar.gz

Standalone Python requires `libcrypt.so.1` to be installed in the host Linux distribution. Where it's not included by default look for a `libxcrypt-compat` package or similar in your distribution package manager and install that.
