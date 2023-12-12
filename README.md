# Deluge Build Tool (DBT) Toolchain

Scripted tooling for fetching toolchain components from multiple sources to build each zip/tarball.

As of right now, Linux, Mac (darwin), and are supported on either of arm64/aarch64 or x86_64 architectures. Windows is supported on x86_64 only.

These toolchains are installed and used by DBT in-place as "portable" or "standalone" style packages. The appropriate toolchain is installed based on which platform the scripts are run from so you should (once DBT is working) not have to download these independently.

The docker workflow tests the build on amd64/x86_64 only.

## Rules for making version changes (new downloadables are only pushed on a version change)

The workflow is run on every push. If you don't want it run on your push, cancel it manually in Github Actions.

The workflow will *only* place/replace the Released files available for download on a new version tag creation (or deletion and recreation of the tag... see the next section if this is needed for some reason). At present, the logic is not very robust so please follow these instructions:

* Only use whole numbers as versions (eg: 9, 10, etc.). *No semantic versioning or decimals*
* Increment the version in ```./VERSION``` *before* pushing tags to Github
* Edit ```./RELEASE.md``` to describe the changes between the current and previous version
* Commit your changes and push them to remote (ensure the build workflow passes before moving on!)
* Using the same version you incremented to in ```./VERSION```, add a tag to an already-pushed commit, prefixed with 'v' (eg: v9, v10). Push tags (with the ```git push --tags``` command)

**Do not use tags for anything else in this repo!**

## Rules for replacing downloadables at the same version

This is not advisable as there's no mechanism for ensuring clients download the new version. That said, there can be good reasons for doing this (like if a newly released toolchain has a problem that's found *before* the version is incremented in the community firmware repo). Follow these steps:

* make sure the version in the ```./VERSION``` file is the same as the one you want to replace
* manually go to github and on the Release page for the version you wish to replace, delete the Release (trash icon in the upper right)
* ```git tag -d v##``` where ## is the same version number
* ```git push --delete origin v##``` where ## is the same version number
* make sure your code changes are already committed and pushed to github (and pass the build workflow!)
* ```git tag v##``` on your local using the same version number in place of ##
* ```git push --tags``` to update remote tags

## Toolchain inclusions

### xpack arm-none-eabi-gcc

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

### xpack OpenOCD

In order to enable support for [DelugeProbe](https://github.com/litui/delugeprobe/) and other third-party debuggers, OpenOCD will need to be used. Here, I've opted for the [latest version from xpack-dev-tools](https://github.com/xpack-dev-tools/openocd-xpack/releases/tag/v0.12.0-1) (without installing xpack as there's little other reason to include node.js):

* Windows x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-win32-x64.zip
* Mac x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-darwin-x64.tar.gz
* Mac arm64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-darwin-arm64.tar.gz
* Linux x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-linux-x64.tar.gz
* Linux arm64/aarch64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-linux-arm64.tar.gz

### Python

Python comes via [Standalone Python](https://github.com/indygreg/python-build-standalone). Packages were chosen for simplicity and compatibility:

* Windows x64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-i686-pc-windows-msvc-static-install_only.tar.gz
* Mac (darwin) x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-x86_64-apple-darwin-install_only.tar.gz
* Mac (darwin) arm64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-aarch64-apple-darwin-install_only.tar.gz
* Linux x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-x86_64-unknown-linux-gnu-install_only.tar.gz
* Linux arm64/aarch64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.11.3+20230507-aarch64-unknown-linux-gnu-install_only.tar.gz

Standalone Python requires `libcrypt.so.1` to be installed in the host Linux distribution. Where it's not included by default look for a `libxcrypt-compat` package or similar in your distribution package manager and install that.

### Some additional odds and ends

* clang-format is included