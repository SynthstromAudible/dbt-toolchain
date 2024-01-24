#!/usr/bin/env bash

# Script to collect all the necessary elements for use in building
# DelugeFirmware source code and modify them appropriately.

VERSION="$(cat VERSION)"

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

XPACK_TOOLS=( "arm-none-eabi-gcc" "openocd" "clang" "cmake" "ninja-build")
XPACK_VERSIONS=( "13.2.1-1.1" "0.12.0-1" "17.0.6-1" "3.26.5-1" "1.11.1-3")

PYTHON_VERSION_TAG="20240107"
PYTHON_VERSION="3.12.1"
# Note: When upgrading Python major/minor version, you must edit the `ln -s` 
# lines below in the python download section

ROOT_DIR="${PWD}"

HOST_PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')

CURL_TOOL=$(which curl)

if [[ ${HOST_PLATFORM} == $LINUX_LABEL ]]; then
    function dbtb_sha256_tool() {
        sha256sum "$1" | awk '{print $1}'
    }

    function dbtb_md5_tool() {
        md5sum "$1" | awk '{print $1}'
    }

    TAR_TOOL="tar"
    HASH_TOOL_SHA256="dbtb_sha256_tool"
    HASH_TOOL_MD5="dbtb_md5_tool"
    CHECK_TOOL_SHA256="sha256sum --check "
elif [[ $HOST_PLATFORM == $DARWIN_LABEL ]]; then
    TAR_TOOL="tar --disable-copyfile"
    HASH_TOOL_SHA256="sha -a 256"
    HASH_TOOL_MD5="md5 -r"
    CHECK_TOOL_SHA256="shasum -c"
fi

dbtb_curl() {
    $CURL_TOOL --progress-bar -SLo "$1" "$2";
}

dbtb_print() {
  echo [ ] $@
}

dbtb_error() {
  echo [-] $@
}

check_downloaded_file() {
    dbtb_print "Checking if $1 exists..";
    if [ ! -f "${STAGING_PATH}/$1" ]; then
        dbtb_error "no";
        return 1;
    fi
    dbtb_print "yes";
    return 0;
}

shift_subdir_up() {
    parent_dir=$1
    if [ $(ls "${os_dest_path}/${parent_dir}" | wc -l | tr -d " ") -lt 2 ]; then
        dbtb_print "Correcting path depth for ${parent_dir}.";
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
    dbtb_print "Unpacking $1 to '$2':";
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
        tar -xvf "${STAGING_PATH}/${tar_file}" --directory "${dest_dir}/${base_dir}.temp" $tar_includes 2>&1 | show_unpack_percentage;
    else
        tar -xvf "${STAGING_PATH}/${tar_file}" --directory "${dest_dir}/${base_dir}.temp" 2>&1 | show_unpack_percentage;
    fi
    mv "${dest_dir}/${base_dir}.temp" "${dest_dir}/${base_dir}" || return 1;
    dbtb_print "done";
    return 0;
}

unzip_archive()
{
    dbtb_print "Unzipping $1 to '$2':";
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
    dbtb_print "done";
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
                        dbtb_print "Downloading ${os_label}-${os_xpack_arch} xpack-${os_xpack_tool}:";
                        dbtb_curl "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.part" ${xpack_tool_path} || return 1;
                        mv "${ROOT_DIR}/${STAGING_PATH}/${xpack_tar}.part" "${STAGING_PATH}/${xpack_tar}";
                    fi

                    dbtb_print 'Checking sha... '
                    cd "${ROOT_DIR}/${STAGING_PATH}";
                    if (grep "${xpack_tar}" ${ROOT_DIR}/shas.txt | ${CHECK_TOOL_SHA256} -); then
                        dbtb_print 'VALID!'
                    else
                        dbtb_error 'INVALID'
                        return 1
                    fi
                    cd "${ROOT_DIR}"

                    dbtb_print "Extracting ${os_label}-${os_xpack_arch} ${os_xpack_tool}:";
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
                    dbtb_print "Downloading ${os_python_label}-${os_python_arch} standalone cpython:";
                    dbtb_curl "${STAGING_PATH}/${python_tar}.part" ${os_python_path} || return 1;
                    mv "${STAGING_PATH}/${python_tar}.part" "${STAGING_PATH}/${python_tar}"
                fi

                dbtb_print "Check Python SHA256"
                if (cd ${STAGING_PATH}; grep "${python_tar}" ${ROOT_DIR}/shas.txt | ${CHECK_TOOL_SHA256} -); then
                    dbtb_print "VALID"
                else
                    dbtb_error "INVALID!"
                    return 1
                fi

                echo "Extracting ${os_python_label}-${os_python_arch} standalone cpython:";
                if [[ $os_python_ext == ".zip" ]]; then
                    unzip_archive $python_tar $os_dest_path python;
                    shift_subdir_up python;
                else
                    untar_archive $python_tar $os_dest_path python;
                    shift_subdir_up python;

                    if [[ $os_python_label != $WIN32_PYTHON_LABEL ]]; then
                        # Create symlinks to fully takeover the python namespace
                        # (critical for gdb-py3 to work right)
                        cd "${os_dest_path}/python/bin";
                        ln -s python3.12 python;
                        ln -s python3.12-config python-config;
                        ln -s pydoc3.12 pydoc;
                        ln -s idle3.12 idle;
                        cd "${ROOT_DIR}";
                    fi
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

    dbtb_print "Adding python lib: $1"

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
    this_os_label=$(uname -s | tr '[:upper:]' '[:lower:]')

    for dist_label in ${OSYSTEMS[@]}; do
        for dist_arch in ${OSYSTEMS_ARCH[@]}; do
            dist_os_path="${dist_label}-${dist_arch}"
            dbtb_print "Packaging ${dist_os_path}"
            if [ -d $dist_os_path ]; then
                tar_file="";
                tar_cmd="";

                if [[ $dist_label == $DARWIN_LABEL || $dist_label == $LINUX_LABEL ]]; then
                    tar_file="dbt-toolchain-${VERSION}-${dist_os_path}.tar.gz"
                    tar_cmd="$TAR_TOOL -zcpf ${DIST_PATH}/${tar_file} ${dist_os_path}"
                elif [ $dist_label == $WIN32_LABEL ]; then
                    tar_file="dbt-toolchain-${VERSION}-${dist_os_path}.zip"
                    tar_cmd="zip -r -x "*.git*" -x "*.DS_Store" -q ${DIST_PATH}/${tar_file} ${dist_os_path}";
                fi

                if [[ $tar_cmd != "" && $tar_file != "" ]]; then
                    $tar_cmd || return 1;
                    cd dist
                    $HASH_TOOL_MD5 "${tar_file}" > "${tar_file}.md5"
                    $HASH_TOOL_SHA256 "${tar_file}" > "${tar_file}.sha256"
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
add_python_lib ansi
add_python_lib "setuptools==69.0.3"

# DIST/PACKAGE
mkdir -p "${DIST_PATH}"

package_dist

dbtb_print "=^._.^= DONE =^._.^="
