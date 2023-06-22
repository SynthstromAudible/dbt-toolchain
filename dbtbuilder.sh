#!/bin/sh

# Script to collect all the necessary elements for use in building
# DelugeFirmware source code and modify them appropriately.

VERSION="8"

DARWIN_LABEL="darwin"
DARWIN_TOOLCHAIN_ARCH=( "arm64" "x86_64" )
DARWIN_XPACK_ARCH=( "arm64" "x64" )
DARWIN_PYTHON_LABEL="apple-darwin"
DARWIN_PYTHON_ARCH=( "aarch64" "x86_64" )
DARWIN_EXTENSION=".tar.bz2"
DARWIN_XPACK_EXT=".tar.gz"
DARWIN_PYTHON_EXT=".tar.gz"

LINUX_LABEL="linux"
LINUX_TOOLCHAIN_ARCH=( "arm64" "x86_64" )
LINUX_XPACK_ARCH=( "arm64" "x64" )
LINUX_PYTHON_LABEL="unknown-linux-gnu"
LINUX_PYTHON_ARCH=( "aarch64" "x86_64" )
LINUX_EXTENSION=".tar.bz2"
LINUX_XPACK_EXT=".tar.gz"
LINUX_PYTHON_EXT=".tar.gz"

WIN32_LABEL="win32"
WIN32_TOOLCHAIN_ARCH=( "x86_64" )
WIN32_XPACK_ARCH=( "x64" )
WIN32_PYTHON_LABEL="pc-windows-msvc-static"
WIN32_PYTHON_ARCH=( "x86_64" )
WIN32_EXTENSION=".zip"
WIN32_XPACK_EXT=".zip"
WIN32_PYTHON_EXT=".tar.gz"

OSYSTEMS=( "${DARWIN_LABEL}" "${LINUX_LABEL}" "${WIN32_LABEL}" )
OSYSTEMS_ARCH=( "arm64" "x86_64" )

DIST_PATH="dist"
STAGING_PATH="staging"

XPACK_TOOLS=( "arm-none-eabi-gcc" "openocd" "clang" )
XPACK_VERSIONS=( "12.2.1-1.2" "0.12.0-1" "14.0.6-2" )

PYTHON_VERSION_TAG="20230507"
PYTHON_VERSION="3.11.3"

ROOT_DIR="${PWD}"

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
    tar_include_list=$4;
    tar_root_dir=$5;
    rm -rf "${dest_dir}/${base_dir}" || return 1;
    rm -rf "${dest_dir}/${base_dir}.temp" || return 1;
    mkdir -p "${dest_dir}/${base_dir}.temp" || return 1;
    if [[ -f "${4}" ]]; then
        tar_includes=$(cat "${tar_include_list}" | awk "{ print \"${tar_root_dir}/\" \$1 }" );
        tar -xvf "${STAGING_PATH}/${tar_file}" -C "${dest_dir}/${base_dir}.temp" $tar_includes 2>&1 | show_unpack_percentage;
    else
        tar -xvf "${STAGING_PATH}/${tar_file}" -C "${dest_dir}/${base_dir}.temp" 2>&1 | show_unpack_percentage;
    fi
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
    zip_include_list=$4;
    zip_root_dir=$5;
    rm -rf "${dest_dir}/${base_dir}" || return 1;
    rm -rf "${dest_dir}/${base_dir}.temp" || return 1;
    mkdir -p "${dest_dir}/${base_dir}.temp" || return 1;
    if [[ -f "${4}" ]]; then
        zip_includes=$(cat "${zip_include_list}" | awk "{ print \"${zip_root_dir}/\" \$1 }" );
        unzip "${STAGING_PATH}/${zip_file}" -d "${dest_dir}/${base_dir}.temp" $zip_includes 2>&1 | show_unpack_percentage;
    else
        unzip "${STAGING_PATH}/${zip_file}" -d "${dest_dir}/${base_dir}.temp" 2>&1 | show_unpack_percentage;
    fi
    mv "${dest_dir}/${base_dir}.temp" "${dest_dir}/${base_dir}" || return 1;
    echo "done";
    return 0;
}

fetch_tools () {
    for os_label in ${OSYSTEMS[@]}; do
        for os_arch in ${OSYSTEMS_ARCH[@]}; do
            os_tc_arch="";
            os_xpack_arch="";
            os_python_arch="";
            os_dest_path="";

            if [[ $os_label == $DARWIN_LABEL ]]; then
                for (( ai=0; ai<${#DARWIN_TOOLCHAIN_ARCH[@]}; ai++ )); do
                    if [ $os_arch == ${DARWIN_TOOLCHAIN_ARCH[$ai]} ]; then
                        os_tc_arch=${DARWIN_TOOLCHAIN_ARCH[$ai]};
                        os_xpack_arch=${DARWIN_XPACK_ARCH[$ai]};
                        os_python_arch=${DARWIN_PYTHON_ARCH[$ai]};
                    fi
                done
                if [[ $os_tc_arch != "" ]]; then
                    os_extension=$DARWIN_EXTENSION;
                    os_xpack_ext=$DARWIN_XPACK_EXT;
                    os_dest_path="${DARWIN_LABEL}-${os_tc_arch}";
                    os_python_label=$DARWIN_PYTHON_LABEL;
                    os_python_ext=$DARWIN_PYTHON_EXT;
                fi
            elif [[ $os_label == $LINUX_LABEL ]]; then
                for (( ai=0; ai<${#LINUX_TOOLCHAIN_ARCH[@]}; ai++)); do
                    if [[ $os_arch == ${LINUX_TOOLCHAIN_ARCH[$ai]} ]]; then
                        os_tc_arch=${LINUX_TOOLCHAIN_ARCH[$ai]};
                        os_xpack_arch=${LINUX_XPACK_ARCH[$ai]};
                        os_python_arch=${LINUX_PYTHON_ARCH[$ai]};
                    fi
                done
                if [[ $os_tc_arch != "" ]]; then
                    os_extension=$LINUX_EXTENSION;
                    os_xpack_ext=$LINUX_XPACK_EXT;
                    os_dest_path="${LINUX_LABEL}-${os_tc_arch}";
                    os_python_label=$LINUX_PYTHON_LABEL;
                    os_python_ext=$LINUX_PYTHON_EXT;
                fi
            elif [[ $os_label == $WIN32_LABEL ]]; then
                for (( ai=0; ai<${#WIN32_TOOLCHAIN_ARCH[@]}; ai++)); do
                    if [[ $os_arch == ${WIN32_TOOLCHAIN_ARCH[$ai]} ]]; then
                        os_tc_arch=${WIN32_TOOLCHAIN_ARCH[$ai]};
                        os_xpack_arch=${WIN32_XPACK_ARCH[$ai]};
                        os_python_arch=${WIN32_PYTHON_ARCH[$ai]};
                    fi
                done
                if [[ $os_tc_arch != "" ]]; then
                    os_extension=$WIN32_EXTENSION;
                    os_xpack_ext=$WIN32_XPACK_EXT;
                    os_dest_path="${WIN32_LABEL}-${os_tc_arch}";
                    os_python_label=$WIN32_PYTHON_LABEL;
                    os_python_ext=$WIN32_PYTHON_EXT;
                fi
            fi

            if [[ $os_tc_arch != "" ]]; then
                rm -rf "${os_dest_path}";
                mkdir -p "${os_dest_path}";

                echo "${VERSION}" > "${os_dest_path}/VERSION";
            fi

            if [[ $os_xpack_arch != "" ]]; then
                for (( i=0; i<${#XPACK_TOOLS[@]}; i++ )); do
                    os_xpack_tool=${XPACK_TOOLS[$i]};
                    os_xpack_version=${XPACK_VERSIONS[$i]};
                    xpack_tool_path="https://github.com/xpack-dev-tools/${os_xpack_tool}-xpack/releases/download/v${os_xpack_version}/xpack-${os_xpack_tool}-${os_xpack_version}-${os_label}-${os_xpack_arch}${os_xpack_ext}";
                    
                    xpack_tar="$(basename "${xpack_tool_path}")";
                    xpack_tar_root_dir="xpack-${os_xpack_tool}-${os_xpack_version}"
                    xpack_tar_include_file="${ROOT_DIR}/config/${os_label}-${os_arch}-${os_xpack_tool}.include";
                    check_downloaded_file "${xpack_tar}";

                    if [[ $? -eq 1 ]]; then
                        echo "Downloading ${os_label}-${os_xpack_arch} xpack-${os_xpack_tool}:";
                        dbtb_curl "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.part" ${xpack_tool_path} || return 1;
                        mv "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.part" "${STAGING_PATH}/${xpack_tar}";
                        echo "Fetching sha hash:";
                        dbtb_curl "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.sha" "${xpack_tool_path}.sha" || return 1;
                        cd "${ROOT_DIR}/${STAGING_PATH}";
                        shasum -c "${xpack_tar}.sha" || return 1;
                        echo "sha valid!";
                        cd "${ROOT_DIR}"
                    else
                        check_downloaded_file "${xpack_tar}.sha";
                        if [[ $? -eq 1 ]]; then
                            dbtb_curl "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.sha" "${xpack_tool_path}.sha" || return 1;
                        fi
                        cd "${ROOT_DIR}/${STAGING_PATH}";
                        shasum -c "${xpack_tar}.sha" || return 1;
                        echo "sha valid!";
                        cd "${ROOT_DIR}";
                    fi

                    echo "Extracting ${os_label}-${os_xpack_arch} ${os_xpack_tool}:";
                    if [ $os_xpack_ext == ".zip" ]; then
                        unzip_archive $xpack_tar $os_dest_path $os_xpack_tool $xpack_tar_include_file $xpack_tar_root_dir;
                        shift_subdir_up $os_xpack_tool
                    else
                        untar_archive $xpack_tar $os_dest_path $os_xpack_tool $xpack_tar_include_file $xpack_tar_root_dir;
                        shift_subdir_up $os_xpack_tool
                    fi
                done
            fi

            if [[ $os_python_arch != "" ]]; then
                os_python_path="https://github.com/indygreg/python-build-standalone/releases/download/${PYTHON_VERSION_TAG}/cpython-${PYTHON_VERSION}+${PYTHON_VERSION_TAG}-${os_python_arch}-${os_python_label}-install_only${os_python_ext}"

                python_tar="$(basename "${os_python_path}")";
                check_downloaded_file "${python_tar}";

                if [[ $? -eq 1 ]]; then
                    echo "Downloading ${os_python_label}-${os_python_arch} standalone cpython:";
                    dbtb_curl "${STAGING_PATH}/${python_tar}.part" ${os_python_path} || return 1;
                    echo "Fetching sha256 hash:";
                    dbtb_curl "${STAGING_PATH}/${python_tar}.sha256" "${os_python_path}.sha256" || return 1;
                    sha256_val=$(shasum -a 256 ${STAGING_PATH}/${python_tar}.part | awk '{print $1}')
                    if [[ $sha256_val == $(cat ${STAGING_PATH}/${python_tar}.sha256) ]]; then
                        mv "${STAGING_PATH}/${python_tar}.part" "${STAGING_PATH}/${python_tar}";
                        echo "sha256 valid!";
                    else
                        echo "sha256 failed!";
                        return 1;
                    fi
                fi

                echo "Extracting ${os_python_label}-${os_python_arch} standalone cpython:";
                if [[ $os_python_ext == ".zip" ]]; then
                    unzip_archive $python_tar $os_dest_path python;
                    shift_subdir_up python
                else
                    untar_archive $python_tar $os_dest_path python;
                    shift_subdir_up python
                fi
            fi
        done    
    done
}

add_python_lib () {
    this_os_label=$(uname -s | tr '[:upper:]' '[:lower:]');
    this_os_arch=$(uname -m | tr '[:upper:]' '[:lower:]');
    this_path="${this_os_label}-${this_os_arch}";

    py_bin="${this_path}/python/bin/python3";
    wheel_dir="${this_path}/python/wheel";
    mkdir -p "${wheel_dir}";

    wheel_files=$($py_bin -m pip wheel -w "${wheel_dir}" $1 | grep -e '\.whl$' | sed -e 's/.*\/\(.*\)$/\1/') || return 1;

    for os_label in ${OSYSTEMS[@]}; do
        for os_arch in ${DARWIN_TOOLCHAIN_ARCH[@]}; do
            target_path="${os_label}-${os_arch}";
            target_wheel=""

            if [[ $target_path != $this_path ]]; then
                if [[ $os_label == $DARWIN_LABEL ]]; then
                    for (( ai=0; ai<${#DARWIN_TOOLCHAIN_ARCH[@]}; ai++ )); do
                        if [ $os_arch == ${DARWIN_TOOLCHAIN_ARCH[$ai]} ]; then
                            target_wheel="${target_path}/python/wheel";
                        fi
                    done
                elif [[ $os_label == $LINUX_LABEL ]]; then
                    for (( ai=0; ai<${#LINUX_TOOLCHAIN_ARCH[@]}; ai++ )); do
                        if [ $os_arch == ${LINUX_TOOLCHAIN_ARCH[$ai]} ]; then
                            target_wheel="${target_path}/python/wheel";
                        fi
                    done
                elif [[ $os_label == $WIN32_LABEL ]]; then
                    for (( ai=0; ai<${#WIN32_TOOLCHAIN_ARCH[@]}; ai++ )); do
                        if [ $os_arch == ${WIN32_TOOLCHAIN_ARCH[$ai]} ]; then
                            target_wheel="${target_path}/python/wheel";
                        fi
                    done
                fi
                if [[ $target_wheel != "" ]]; then
                    mkdir -p $target_wheel;

                    for wheel in ${wheel_files[@]}; do
                        cp "${wheel_dir}/${wheel}" "${target_wheel}";
                    done
                fi
            fi
        done
    done
}

package_dist () {
    rm -rf "${DIST_PATH}/*"

    for dist_label in ${OSYSTEMS[@]}; do
        for dist_arch in ${OSYSTEMS_ARCH[@]}; do
            dist_os_path="${dist_label}-${dist_arch}"
            if [ -d $dist_os_path ]; then
                tar_file="";
                tar_cmd="";

                if [[ $dist_label == $DARWIN_LABEL || $dist_label == $LINUX_LABEL ]]; then
                    tar_file="dbt-toolchain-${VERSION}-${dist_os_path}.tar.gz"
                    tar_cmd="tar --disable-copyfile -zcpf ${DIST_PATH}/${tar_file} ${dist_os_path}";
                elif [ $dist_label == $WIN32_LABEL ]; then
                    tar_file="dbt-toolchain-${VERSION}-${dist_os_path}.zip"
                    tar_cmd="zip -r -x "*.git*" -x "*.DS_Store" -q ${DIST_PATH}/${tar_file} ${dist_os_path}";
                fi

                if [[ $tar_cmd != "" && $tar_file != "" ]]; then
                    $tar_cmd || return 1;
                    cd dist
                    md5 -r "${tar_file}" > "${tar_file}.md5"
                    shasum -a 256 "${tar_file}" > "${tar_file}.sha256"
                    cd ..
                fi
            fi
        done
    done
    
}

# Location for all the files downloaded.
mkdir -p "${STAGING_PATH}"

# Fetch, verify, and extract all the required toolchain tools
fetch_tools

add_python_lib certifi
add_python_lib pyserial
add_python_lib ansi
add_python_lib SCons

# DIST/PACKAGE
mkdir -p "${DIST_PATH}"

package_dist
