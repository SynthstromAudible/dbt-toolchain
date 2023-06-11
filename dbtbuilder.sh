#!/bin/sh

# Script to collect all the necessary elements for use in building
# DelugeFirmware source code and modify them appropriately.

VERSION="5"

DARWIN_LABEL="darwin"
DARWIN_PYTHON_LABEL="apple-darwin"
DARWIN_TOOLCHAIN_ARCH="x86_64"
DARWIN_OPENOCD_ARCH="x64"
DARWIN_PYTHON_ARCH="x86_64"
DARWIN_PATH="${DARWIN_LABEL}-${DARWIN_TOOLCHAIN_ARCH}"
DARWIN_EXTENSION=".tar.bz2"
DARWIN_OPENOCD_EXT=".tar.gz"
DARWIN_PYTHON_EXT=".tar.gz"

LINUX_LABEL="linux"
LINUX_PYTHON_LABEL="unknown-linux-gnu"
LINUX_TOOLCHAIN_ARCH="x86_64"
LINUX_OPENOCD_ARCH="x64"
LINUX_PYTHON_ARCH="x86_64"
LINUX_PATH="${LINUX_LABEL}-${LINUX_TOOLCHAIN_ARCH}"
LINUX_EXTENSION=".tar.bz2"
LINUX_OPENOCD_EXT=".tar.gz"
LINUX_PYTHON_EXT=".tar.gz"

WIN32_LABEL="win32"
WIN32_PYTHON_LABEL="pc-windows-msvc-static"
WIN32_TOOLCHAIN_ARCH="x86_64"
WIN32_OPENOCD_ARCH="x64"
WIN32_PYTHON_ARCH="x86_64"
WIN32_PATH="${WIN32_LABEL}-${WIN32_TOOLCHAIN_ARCH}"
WIN32_EXTENSION=".zip"
WIN32_OPENOCD_EXT=".zip"
WIN32_PYTHON_EXT=".tar.gz"

OSYSTEMS=( "${DARWIN_LABEL}" "${LINUX_LABEL}" "${WIN32_LABEL}" )

DIST_PATH="dist"
STAGING_PATH="staging"

TOOLCHAIN_VERSION="9-2019-q4-major"
TOOLCHAIN_REMOTE_PATH="https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4"

OPENOCD_VERSION="0.12.0-1"

PYTHON_VERSION_TAG="20230507"
PYTHON_VERSION="3.10.11"

CURL_TOOL=$(which curl)

dbtb_curl() {
    $CURL_TOOL --progress-bar -SLo "$1" "$2";
}

check_downloaded_file() {
    echo "Checking if $1 exists..";
    if [ ! -f "${STAGING_PATH}/$1" ]; then
        echo "no";
        return 1;
    fi
    echo "yes";
    return 0;
}

shift_subdir_up() {
    parent_dir=$1
    if [ $(ls "${os_dest_path}/${parent_dir}" | wc -l | tr -d " ") -lt 2 ]; then
        echo "Correcting path depth for ${parent_dir}.";
        openocd_subdir=$(ls "${os_dest_path}/${parent_dir}" | head -n 1);
        mv "${os_dest_path}/${parent_dir}" "${os_dest_path}/${parent_dir}.wrong";
        mv "${os_dest_path}/${parent_dir}.wrong/${openocd_subdir}" "${os_dest_path}/${parent_dir}";
        rmdir "${os_dest_path}/${parent_dir}.wrong";
    fi
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

untar_archive()
{
    echo "Unpacking $1 to '$2':";
    tar_file=$1;
    dest_dir=$2;
    base_dir=$3;
    rm -rf "${dest_dir}/${base_dir}" || return 1;
    rm -rf "${dest_dir}/${base_dir}.temp" || return 1;
    mkdir -p "${dest_dir}/${base_dir}.temp" || return 1;
    tar -xvf "${STAGING_PATH}/${tar_file}" -C "${dest_dir}/${base_dir}.temp" 2>&1 | show_unpack_percentage;
    mv "${dest_dir}/${base_dir}.temp" "${dest_dir}/${base_dir}" || return 1;
    echo "done";
    return 0;
}

unzip_archive()
{
    echo "Unzipping $1 to '$2':";
    zip_file=$1;
    dest_dir=$2;
    base_dir=$3;
    rm -rf "${dest_dir}/${base_dir}" || return 1;
    rm -rf "${dest_dir}/${base_dir}.temp" || return 1;
    mkdir -p "${dest_dir}/${base_dir}.temp" || return 1;
    unzip "${STAGING_PATH}/${zip_file}" -d "${dest_dir}/${base_dir}.temp" 2>&1 | show_unpack_percentage;
    mv "${dest_dir}/${base_dir}.temp" "${dest_dir}/${base_dir}" || return 1;
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
            os_openocd_ext=$DARWIN_OPENOCD_EXT

            os_python_label=$DARWIN_PYTHON_LABEL
            os_python_arch=$DARWIN_PYTHON_ARCH
            os_python_ext=$DARWIN_PYTHON_EXT
        elif [ $os_label == $LINUX_LABEL ]; then
            os_toolchain_arch=$LINUX_TOOLCHAIN_ARCH
            os_extension=$LINUX_EXTENSION
            os_toolchain_path="${TOOLCHAIN_REMOTE_PATH}/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}-${os_toolchain_arch}-${os_label}${os_extension}"
            os_toolchain_md5="fe0029de4f4ec43cf7008944e34ff8cc"
            os_dest_path="${LINUX_PATH}"

            os_openocd_arch=$LINUX_OPENOCD_ARCH
            os_openocd_ext=$LINUX_OPENOCD_EXT

            os_python_label=$LINUX_PYTHON_LABEL
            os_python_arch=$LINUX_PYTHON_ARCH
            os_python_ext=$LINUX_PYTHON_EXT
        elif [ $os_label == $WIN32_LABEL ]; then
            os_toolchain_arch=$WIN32_TOOLCHAIN_ARCH
            os_extension=$WIN32_EXTENSION
            os_toolchain_path="${TOOLCHAIN_REMOTE_PATH}/gcc-arm-none-eabi-${TOOLCHAIN_VERSION}-${os_label}${os_extension}"
            os_toolchain_md5="82525522fefbde0b7811263ee8172b10"
            os_dest_path="${WIN32_PATH}"

            os_openocd_arch=$WIN32_OPENOCD_ARCH
            os_openocd_ext=$WIN32_OPENOCD_EXT

            os_python_label=$WIN32_PYTHON_LABEL
            os_python_arch=$WIN32_PYTHON_ARCH
            os_python_ext=$WIN32_PYTHON_EXT
        fi
        
        if [ $os_toolchain_arch != "" ]; then
            toolchain_tar="$(basename "${os_toolchain_path}")";
            check_downloaded_file "${toolchain_tar}";
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
            if [ $os_extension == ".zip" ]; then
                unzip_archive $toolchain_tar $os_dest_path gcc-arm;
                shift_subdir_up gcc-arm
            else
                untar_archive $toolchain_tar $os_dest_path gcc-arm;
                shift_subdir_up gcc-arm
            fi
        fi

        if [ $os_openocd_arch != "" ]; then
            os_openocd_path="https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v${OPENOCD_VERSION}/xpack-openocd-${OPENOCD_VERSION}-${os_label}-${os_openocd_arch}${os_openocd_ext}"

            # echo "${os_openocd_path}"
            openocd_tar="$(basename "${os_openocd_path}")";
            check_downloaded_file "${openocd_tar}";

            if [ $? -eq 1 ]; then
                echo "Downloading ${os_label}-${os_openocd_arch} xpack-openocd:";
                dbtb_curl "${STAGING_PATH}/${openocd_tar}.part" ${os_openocd_path} || return 1;
                mv "${STAGING_PATH}/${openocd_tar}.part" "${STAGING_PATH}/${openocd_tar}";
                echo "Fetching sha hash:";
                dbtb_curl "${STAGING_PATH}/${openocd_tar}.sha" "${os_openocd_path}.sha" || return 1;
                cd "${STAGING_PATH}";
                shasum -c "${openocd_tar}.sha" || return 1;
                echo "sha valid!";
                cd ..
            else
                cd "${STAGING_PATH}";
                shasum -c "${openocd_tar}.sha" || return 1;
                echo "sha valid!";
                cd ..
            fi

            echo "Extracting ${os_label}-${os_openocd_arch} openocd:";
            if [ $os_openocd_ext == ".zip" ]; then
                unzip_archive $openocd_tar $os_dest_path openocd;
                shift_subdir_up openocd
            else
                untar_archive $openocd_tar $os_dest_path openocd;
                shift_subdir_up openocd
            fi
        fi

        if [ $os_python_arch != "" ]; then
            os_python_path="https://github.com/indygreg/python-build-standalone/releases/download/${PYTHON_VERSION_TAG}/cpython-${PYTHON_VERSION}+${PYTHON_VERSION_TAG}-${os_python_arch}-${os_python_label}-install_only${os_python_ext}"

            python_tar="$(basename "${os_python_path}")";
            check_downloaded_file "${python_tar}";

            if [ $? -eq 1 ]; then
                echo "Downloading ${os_python_label}-${os_python_arch} standalone cpython:";
                dbtb_curl "${STAGING_PATH}/${python_tar}.part" ${os_python_path} || return 1;
                echo "Fetching sha256 hash:";
                dbtb_curl "${STAGING_PATH}/${python_tar}.sha256" "${os_python_path}.sha256" || return 1;
                sha256_val=$(shasum -a 256 ${STAGING_PATH}/${python_tar}.part | awk '{print $1}')
                if [ $sha256_val == $(cat ${STAGING_PATH}/${python_tar}.sha256) ]; then
                    mv "${STAGING_PATH}/${python_tar}.part" "${STAGING_PATH}/${python_tar}";
                    echo "sha256 valid!";
                else
                    echo "sha256 failed!";
                    return 1;
                fi
            fi

            echo "Extracting ${os_python_label}-${os_python_arch} standalone cpython:";
            if [ $os_python_ext == ".zip" ]; then
                unzip_archive $python_tar $os_dest_path python;
                shift_subdir_up python
            else
                untar_archive $python_tar $os_dest_path python;
                shift_subdir_up python
            fi
        fi
    done
}

add_python_lib () {
    # We are on darwin, so let's set up the appropriate libraries
    # on darwin, then move them over to the other paths as
    # needed.

    py_bin="${DARWIN_PATH}/python/bin/python3";
    wheel_dir="${DARWIN_PATH}/python/wheel";
    mkdir -p "${wheel_dir}";

    wheel_file=$($py_bin -m pip wheel -w "${wheel_dir}" $1 | tail -1 | sed -e 's/.*\/\(.*\)$/\1/') || return 1;
    echo $wheel_file
    mkdir -p "${LINUX_PATH}/python/wheel";
    mkdir -p "${WIN32_PATH}/python/wheel";
    cp "${wheel_dir}/${wheel_file}" "${LINUX_PATH}/python/wheel";
    cp "${wheel_dir}/${wheel_file}" "${WIN32_PATH}/python/wheel";
}

package_dist () {
    rm -rf "${DIST_PATH}/*"

    for dist_label in ${OSYSTEMS[@]}; do
        tar_cmd="";
        if [ $dist_label == $DARWIN_LABEL ]; then
            dist_os_path=$DARWIN_PATH;
            tar_file="dbt-toolchain-${VERSION}-${DARWIN_PATH}.tar.gz"
            tar_cmd="tar -zcpf ${DIST_PATH}/${tar_file} ${DARWIN_PATH}";
        elif [ $dist_label == $LINUX_LABEL ]; then
            dist_os_path=$LINUX_PATH;
            tar_file="dbt-toolchain-${VERSION}-${LINUX_PATH}.tar.gz"
            tar_cmd="tar -zcpf ${DIST_PATH}/${tar_file} ${LINUX_PATH}";
        elif [ $dist_label == $WIN32_LABEL ]; then
            dist_os_path=$WIN32_PATH;
            tar_file="dbt-toolchain-${VERSION}-${WIN32_PATH}.zip"
            tar_cmd="zip -r -q ${DIST_PATH}/${tar_file} ${WIN32_PATH}";
        fi

        if [ "${tar_cmd}" != "" ]; then
            $tar_cmd || return 1;
            cd dist
            md5 -r "${tar_file}" > "${tar_file}.md5"
            shasum -a 256 "${tar_file}" > "${tar_file}.sha256"
            cd ..
        fi
    done
    
}

# Location for all the files downloaded.
mkdir -p "${STAGING_PATH}"

# Fetch, verify, and extract all the required toolchain tools
# fetch_tools

# add_python_lib certifi
# add_python_lib pip
# add_python_lib pyserial
# add_python_lib ansi

# DIST/PACKAGE
mkdir -p "${DIST_PATH}"

mkdir -p "${DARWIN_PATH}"
echo "${VERSION}" > "${DARWIN_PATH}/VERSION"
mkdir -p "${LINUX_PATH}"
echo "${VERSION}" > "${LINUX_PATH}/VERSION"
mkdir -p "${WIN32_PATH}"
echo "${VERSION}" > "${WIN32_PATH}/VERSION"

package_dist
