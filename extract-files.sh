#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=camera
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function apktool_patch() {
    local APK_PATH="$1"
    shift

    local PATCHES_PATH="$1"
    shift

    local PATCHES_PATHS=$(find "$PATCHES_PATH" -name "*.patch" | sort)
    local APKTOOL_FRAMEWORK_ARGS=()

    if [ "${SRC}" != "adb" ]; then
        local FRAMEWORK_APK=""

        for FRAMEWORK_APK_PATH in \
            "${SRC}/system/system/framework/framework-res.apk" \
            "${SRC}/system/framework/framework-res.apk"; do
            if [ -f "${FRAMEWORK_APK_PATH}" ]; then
                FRAMEWORK_APK="${FRAMEWORK_APK_PATH}"
                break
            fi
        done

        if [ -n "${FRAMEWORK_APK}" ]; then
            local FRAMEWORK_DIR="${EXTRACT_TMP_DIR}/apktool-framework"
            mkdir -p "${FRAMEWORK_DIR}"
            apktool if "${FRAMEWORK_APK}" -p "${FRAMEWORK_DIR}"
            APKTOOL_FRAMEWORK_ARGS=(-p "${FRAMEWORK_DIR}")
        fi
    fi

    local TEMP_DIR=$(mktemp -dp "$EXTRACT_TMP_DIR")
    apktool d "${APKTOOL_FRAMEWORK_ARGS[@]}" "$APK_PATH" -o "$TEMP_DIR" -f "$@"

    while IFS= read -r PATCH_PATH; do
        echo "Applying patch $PATCH_PATH"
        # unsafe-paths is required since the directory is outside of the current working directory
        git apply --unsafe-paths --directory="$TEMP_DIR" "$PATCH_PATH"
    done <<<"$PATCHES_PATHS"

    apktool b "${APKTOOL_FRAMEWORK_ARGS[@]}" "$TEMP_DIR" -o "$APK_PATH"

    "$STRIPZIP" "$APK_PATH"
}

function blob_fixup() {
    case "${1}" in
        system/lib64/libcamera_algoup_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            patchelf --add-needed libgui_shim_miuicamera.so "${2}"
            sed -i "s/\x08\xad\x40\xf9/\x08\xa9\x40\xf9/" "${2}"
            ;;
        system/lib64/libcamera_mianode_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed libgui_shim_miuicamera.so "${2}"
            ;;
        system/priv-app/MiuiCamera/MiuiCamera.apk)
            [ "$2" = "" ] && return 0
            apktool_patch "${2}" "$MY_DIR/patches"
            split --bytes=20M -d "$2" "$2".part
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
