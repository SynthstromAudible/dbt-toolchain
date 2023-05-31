# Deluge Build Tool (DBT) Toolchain

The source repo for this is still a work-in-progress as it fetches from multiple sources to build each zip/tarball. Currently this is a manual process of downloading, extraction, renaming, and archiving, but it will be scripted in the coming days.

As of right now, only x86_64 is supported on each platform. This is primarily due to the availability of earlier versions of arm-none-eabi tools. As the DelugeFirmware project matures, I expect we'll see a move to more recent versions of the tooling, and with that a shift to support for other architectures including Windows 11 ARM64 and Mac (darwin) ARM64.

These toolchains are installed and used by DBT in-place as "portable" or "standalone" style packages. The appropriate toolchain is installed based on which platform the scripts are run from so you should (once DBT is working) not have to download these independently.

## arm-none-eabi Tools

There are three officially supported toolchain versions for the Renesas RZ/A series in e<sup>2</sup> studio:
* 6-2017-q2-update
* 9-2019-q4-major
* 9-2020-q2-update

For DBT I've initially opted to include [9-2019-q4-major](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads/9-2019-q4-major) as this is the toolchain used by Synthstrom Audible developers to this point. Packages included are as follows:

* Windows x86 (32bit): https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-win32.zip?revision=20c5df9c-9870-47e2-b994-2a652fb99075&rev=20c5df9c987047e2b9942a652fb99075&hash=DBEB34DE4AB3A1EB549D64C02F2E426080226698
* Mac (darwin) x86_64: https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-mac.tar.bz2?revision=c2c4fe0e-c0b6-4162-97e6-7707e12f2b6e&rev=c2c4fe0ec0b6416297e67707e12f2b6e&hash=052073834B7604AEB73C4E2BA032144EA104B5CD
* Linux x86_64: https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2?revision=108bd959-44bd-4619-9c19-26187abf5225&rev=108bd95944bd46199c1926187abf5225&hash=3587BB8F9E458752D7057C56DCF3171DEC0463B4

## xpack OpenOCD

In order to enable support for [DelugeProbe](https://github.com/litui/delugeprobe/) and other third-party debuggers, OpenOCD will need to be used. Here, I've opted for the [latest version from xpack-dev-tools](https://github.com/xpack-dev-tools/openocd-xpack/releases/tag/v0.12.0-1) (without installing xpack as there's little other reason to include node.js):

* Windows x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-win32-x64.zip
* Mac x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-darwin-x64.tar.gz
* Linux x64: https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-1/xpack-openocd-0.12.0-1-linux-x64.tar.gz

## Python

Python comes via [Standalone Python](https://github.com/indygreg/python-build-standalone). Packages were chosen for simplicity and compatibility:

* Windows x64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.10.11+20230507-x86_64-pc-windows-msvc-static-install_only.tar.gz
* Mac (darwin) x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.10.11+20230507-x86_64-apple-darwin-install_only.tar.gz
* Linux x86_64: https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.10.11+20230507-x86_64-unknown-linux-gnu-install_only.tar.gz