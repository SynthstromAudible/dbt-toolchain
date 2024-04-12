# Deluge Build Tool (DBT) Toolchain

Scripted tooling for fetching toolchain components from multiple sources to build each zip/tarball.

As of right now, Linux, Mac (darwin), and are supported on either of arm64/aarch64 or x86_64 architectures. Windows is supported on x86_64 only.

These toolchains are installed and used by DBT in-place as "portable" or "standalone" style packages. The appropriate toolchain is installed based on which platform the scripts are run from so you should (once DBT is working) not have to download these independently.

The docker workflow tests the build on amd64/x86_64 only.

## Rules for making version changes (new downloadables are only pushed on a version change)

The workflow is run on every push. If you don't want it run on your push, cancel it manually in Github Actions.

The workflow will *only* place/replace the Released files available for download on a new version tag creation (or deletion and recreation of the tag... see the next section if this is needed for some reason). At present, the logic is not very robust so please follow these instructions:

* Only use whole numbers as versions (eg: 9, 10, etc.). *No semantic versioning or decimals*
* Increment the version in ```./config.toml``` *before* pushing tags to Github
* Edit ```./RELEASE.md``` to describe the changes between the current and previous version
* Commit your changes and push them to remote (ensure the build workflow passes before moving on!)
* Using the same version you incremented to in ```./config.toml```, add a tag to an already-pushed commit, prefixed with 'v' (eg: v9, v10). Push tags (with the ```git push --tags``` command)

**Do not use tags for anything else in this repo!**

## Rules for replacing downloadables at the same version

This is not advisable as there's no mechanism for ensuring clients download the new version. That said, there can be good reasons for doing this (like if a newly released toolchain has a problem that's found *before* the version is incremented in the community firmware repo). Follow these steps:

* make sure the version in the ```./config.toml``` file is the same as the one you want to replace
* manually go to github and on the Release page for the version you wish to replace, delete the Release (trash icon in the upper right)
* ```git tag -d v##``` where ## is the same version number
* ```git push --delete origin v##``` where ## is the same version number
* make sure your code changes are already committed and pushed to github (and pass the build workflow!)
* ```git tag v##``` on your local using the same version number in place of ##
* ```git push --tags``` to update remote tags

## Toolchain inclusions
See config.toml for list of packages and their relevant versions

### Details:
#### xpack OpenOCD
In order to enable support for [DelugeProbe](https://github.com/litui/delugeprobe/) and other third-party debuggers, OpenOCD will need to be used.

#### Python
Standalone Python requires `libcrypt.so.1` to be installed in the host Linux distribution. Where it's not included by default look for a `libxcrypt-compat` package or similar in your distribution package manager and install that.
