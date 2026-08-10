#!/bin/bash
# shellcheck source=/dev/null
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/utils.sh"

ID=${1:-$(resolve_latest_github_stable_release_tag "FreeRDP" "FreeRDP" '^[0-9]+(\.[0-9]+)*$')}
PACKAGE_NAME="freerdp3"
PROJECT_URL="https://github.com/FreeRDP/FreeRDP"
ARCHIVE_URL="${PROJECT_URL}/archive/refs/tags/${ID}.tar.gz"
LICENSE_URL="https://raw.githubusercontent.com/FreeRDP/FreeRDP/${ID}/LICENSE"
CURRENT_ID=$(sed -nE 's/^FREERDP3_VERSION = (.*)$/\1/p' "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.mk" | head -n1)

if [[ -z "${1}" ]]; then
  exit_if_version_unchanged "${CURRENT_ID}" "${ID}" "${PACKAGE_NAME}"
fi

if ! wget --passive-ftp -nd -t 3 --spider "${ARCHIVE_URL}"; then
  echo "Failed to download archive for ${PACKAGE_NAME}" >&2
  exit 1
fi

if ! wget --passive-ftp -nd -t 3 --spider "${LICENSE_URL}"; then
  echo "Failed to download LICENSE for ${PACKAGE_NAME}" >&2
  exit 1
fi

ARCHIVE_HASH=$(wget --passive-ftp -nd -t 3 -O - "${ARCHIVE_URL}" | sha256sum | awk '{ print $1 }')
LICENSE_HASH=$(wget --passive-ftp -nd -t 3 -O - "${LICENSE_URL}" | sha256sum | awk '{ print $1 }')
if [[ -n "${ARCHIVE_HASH}" && -n "${LICENSE_HASH}" ]]; then
  sed -i "s/^FREERDP3_VERSION = .*/FREERDP3_VERSION = ${ID}/g" "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.mk"
  sed -i "/ ${PACKAGE_NAME}-.*\\.tar\\.gz\$/d" "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
  sed -i "/ LICENSE\$/d" "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
  echo "sha256  ${ARCHIVE_HASH}  ${PACKAGE_NAME}-${ID}.tar.gz" >>"buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
  echo "sha256  ${LICENSE_HASH}  LICENSE" >>"buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
else
  echo "Failed to retrieve archive or license hash for ${PACKAGE_NAME}" >&2
  exit 1
fi
