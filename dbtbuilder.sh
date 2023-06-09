#!/bin/sh

# Script to collect all the necessary elements for use in building
# DelugeFirmware source code and modify them appropriately.

VERSION="5"

DARWIN_LABEL="darwin"
DARWIN_TOOLCHAIN_ARCH="x86_64"
DARWIN_OPENOCD_ARCH="x64"
DARWIN_PATH="${DARWIN_LABEL}-${DARWIN_TOOLCHAIN_ARCH}"
DARWIN_EXTENSION=".tar.bz2"
DARWIN_OPENOCD_EXT=".tar.gz"

LINUX_LABEL="linux"
LINUX_TOOLCHAIN_ARCH="x86_64"
LINUX_OPENOCD_ARCH="x64"
LINUX_PATH="${LINUX_LABEL}-${LINUX_TOOLCHAIN_ARCH}"
LINUX_EXTENSION=".tar.bz2"
LINUX_OPENOCD_EXT=".tar.gz"

WIN32_LABEL="win32"
WIN32_TOOLCHAIN_ARCH="x86_64"
WIN32_OPENOCD_ARCH="x64"
WIN32_PATH="${WIN32_LABEL}-${WIN32_TOOLCHAIN_ARCH}"
WIN32_EXTENSION=".zip"
WIN32_OPENOCD_EXT=".zip"

OSYSTEMS=( "${DARWIN_LABEL}" "${LINUX_LABEL}" "${WIN32_LABEL}" )

DIST_PATH="dist"
STAGING_PATH="staging"

TOOLCHAIN_VERSION="9-2019-q4-major"
TOOLCHAIN_REMOTE_PATH="https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4"

OPENOCD_VERSION="0.12.0-1"

CURL_TOOL=$(which curl)

dbtb_curl() {
    $CURL_TOOL --progress-bar -SLo "$1" "$2";
}

check_downloaded_toolchain() {
    printf "Checking if downloaded toolchain file exists..";
    if [ ! -f "${STAGING_PATH}/$1" ]; then
        echo "no";
        return 1;
    fi
    echo "yes";
    return 0;
}

show_unpack_percentage()
{
    LINE=0;
    while read -r line; do
        LINE=$(( LINE + 1 ));
        if [ $(( LINE % 300 )) -eq 0 ]; then
            printf "#";
        fi
    done
    echo " 100.0%";
}

untar_toolchain()
{
    echo "Unpacking $1 to '$2':";
    tar_file=$1;
    dest_dir=$2;
    rm -rf "${dest_dir}/gcc-arm" || return 1;
    rm -rf "${dest_dir}/gcc-arm.temp" || return 1;
    mkdir -p "${dest_dir}/gcc-arm.temp" || return 1;
    tar -xvf "${STAGING_PATH}/${tar_file}" -C "${dest_dir}/gcc-arm.temp" 2>&1 | show_unpack_percentage;
    mv "${dest_dir}/gcc-arm.temp" "${dest_dir}/gcc-arm" || return 1;
    echo "done";
    return 0;
}

unzip_toolchain()
{
    echo "Unzipping $1 to '$2':";
    zip_file=$1;
    dest_dir=$2;
    rm -rf "${dest_dir}/gcc-arm" || return 1;
    rm -rf "${dest_dir}/gcc-arm.temp" || return 1;
    mkdir -p "${dest_dir}/gcc-arm.temp" || return 1;
    unzip -v "${STAGING_PATH}/${zip_file}" -d "${dest_dir}/gcc-arm.temp" 2>&1 | show_unpack_percentage;
    mv "${dest_dir}/gcc-arm.temp" "${dest_dir}/gcc-arm" || return 1;
    echo "done";
    return 0;
}

fetch_tools () {
    for os_label in ${OSYSTEMS[@]}; do
        os_toolchain_arch=""
        os_openocd_arch=""
        if [ $os_label == $DARWIN_LABEL ]; then
            os_toolchain_arch=$DARWIN_TOOLCHAIN_ARCH
            os_extension=$DARWIN_EXTENSION
            os_toolchain_path="${TOOLCHAIN_REMOTE_PATH}/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}-mac${os_extension}"
            os_toolchain_md5="241b64f0578db2cf146034fc5bcee3d4"
            os_dest_path="${DARWIN_PATH}"

            os_openocd_arch=$DARWIN_OPENOCD_ARCH
        elif [ $os_label == $LINUX_LABEL ]; then
            os_toolchain_arch=$LINUX_TOOLCHAIN_ARCH
            os_extension=$LINUX_EXTENSION
            os_toolchain_path="${TOOLCHAIN_REMOTE_PATH}/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}-${os_toolchain_arch}-${os_label}${os_extension}"
            os_toolchain_md5="fe0029de4f4ec43cf7008944e34ff8cc"
            os_dest_path="${LINUX_PATH}"

            os_openocd_arch=$LINUX_OPENOCD_ARCH
        elif [ $os_label == $WIN32_LABEL ]; then
            os_toolchain_arch=$WIN32_TOOLCHAIN_ARCH
            os_extension=$WIN32_EXTENSION
            os_toolchain_path="${TOOLCHAIN_REMOTE_PATH}/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}-${os_label}${os_extension}"
            os_toolchain_md5="82525522fefbde0b7811263ee8172b10"
            os_dest_path="${WIN32_PATH}"

            os_openocd_arch=$WIN32_OPENOCD_ARCH
        fi
        
        if [ $os_toolchain_arch != "" ]; then
            toolchain_tar="$(basename "${os_toolchain_path}")";
            check_downloaded_toolchain "${toolchain_tar}";
            if [ $? -eq 1 ]; then
                echo "Downloading ${os_label}-${os_toolchain_arch} toolchain:";
                dbtb_curl "${STAGING_PATH}/${toolchain_tar}.part" "${os_toolchain_path}" || return 1;
                md5_result=$(md5 "${STAGING_PATH}/${toolchain_tar}.part" | sed -e 's/^.* = \(.*\)$/\1/');
                if [ $md5_result == $os_toolchain_md5 ]; then
                    mv "${STAGING_PATH}/${toolchain_tar}.part" "${STAGING_PATH}/${toolchain_tar}"
                    echo "md5 valid!";
                else
                    echo "md5 failed!";
                    return 1;
                fi
                echo "done";
            else
                md5_result=$(md5 "${STAGING_PATH}/${toolchain_tar}" | sed -e 's/^.* = \(.*\)$/\1/');
                if [ $md5_result == $os_toolchain_md5 ]; then
                    echo "md5 valid!";
                else
                    echo "md5 failed!";
                    return 1;
                fi
            fi

            echo "Extracting ${os_label}-${os_toolchain_arch} toolchain:";
            if [ os_extension == ".zip" ]; then
                unzip_toolchain $toolchain_tar $os_dest_path;
            else
                untar_toolchain $toolchain_tar $os_dest_path;
            fi
        fi

        if [ $os_openocd_arch != "" ]; then
            os_openocd_path="https://github.com/xpack-dev-tools/openocd-xpack/releases/download/${OPENOCD_VERSION}/xpack-openocd-${OPENOCD_VERSION}-${os_label}-${os_openocd_arch}.tar.gz"

            openocd_tar="$(basename "${os_openocd_path}")";
            check_downloaded_toolchain "${openocd_tar}";
            if [ $? -eq 1 ]; then
                echo "Downloading ${os_label}-${os_openocd_arch} openocd:";
                
            fi
        fi
    done
}

# Location for all the files downloaded.
mkdir -p "${STAGING_PATH}"

fetch_tools


# DIST/PACKAGE
mkdir -p "${DIST_PATH}"

mkdir -p "${DARWIN_PATH}"
echo "${VERSION}" > "${DARWIN_PATH}/VERSION"
mkdir -p "${LINUX_PATH}"
echo "${VERSION}" > "${LINUX_PATH}/VERSION"
mkdir -p "${WIN32_PATH}"
echo "${VERSION}" > "${WIN32_PATH}/VERSION"

