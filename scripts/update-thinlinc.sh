#!/bin/bash
# shellcheck source=/dev/null
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/utils.sh"

function resolve_latest_thinlinc_version() {
  local project_url=${1}
  local listing
  local version

  if ! listing=$(wget --passive-ftp -nd -t 3 -O - "${project_url}/" 2>/dev/null); then
    return 1
  fi

  version=$(echo "${listing}" \
    | grep -oE 'tl-[0-9]+(\.[0-9]+)*-[0-9]+-client-linux-dynamic-x86_64\.tar\.gz' \
    | sed -E 's/^tl-//; s/-client-linux-dynamic-x86_64\.tar\.gz$//' \
    | sort -uV \
    | tail -n1)

  if [[ -z "${version}" ]]; then
    return 1
  fi

  echo "${version}"
}

PACKAGE_NAME="thinlinc"
PROJECT_URL="https://www.cendio.com/downloads/clients"
if [[ -n "${1}" ]]; then
  ID=${1}
else
  ID=$(resolve_latest_thinlinc_version "${PROJECT_URL}" || true)
  if [[ -z "${ID}" ]]; then
    echo "Failed to resolve latest ${PACKAGE_NAME} version automatically. Please pass version manually." >&2
    exit 1
  fi
fi

ARCHIVE_URL="${PROJECT_URL}/tl-${ID}-client-linux-dynamic-CPU.tar.gz"
CURRENT_ID=$(sed -nE 's/^THINLINC_VERSION = (.*)$/\1/p' "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.mk" | head -n1)

if [[ -z "${1}" ]]; then
  exit_if_version_unchanged "${CURRENT_ID}" "${ID}" "${PACKAGE_NAME}"
fi

function update_hash() {
  local cpu=${1}
  local url=${ARCHIVE_URL/CPU/${cpu}}

  if ! wget --passive-ftp -nd -t 3 --spider "${url}"; then
    echo "Failed to download archive for ${PACKAGE_NAME} (${cpu})" >&2
    exit 1
  fi

  local archive_hash
  archive_hash=$(wget --passive-ftp -nd -t 3 -O - "${url}" | sha256sum | awk '{ print $1 }')
  if [[ -n "${archive_hash}" ]]; then
    sed -i "/-${cpu}\.tar.gz/d" "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
    echo "sha256  ${archive_hash}  tl-${ID}-client-linux-dynamic-${cpu}.tar.gz" >>"buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.hash"
  else
    echo "Failed to retrieve archive hash for ${PACKAGE_NAME} (${cpu})" >&2
    exit 1
  fi
}

BR_PACKAGE_NAME=${PACKAGE_NAME^^}
BR_PACKAGE_NAME=${BR_PACKAGE_NAME//-/_}
sed -i "s/${BR_PACKAGE_NAME}_VERSION = .*/${BR_PACKAGE_NAME}_VERSION = ${ID}/g" "buildroot-external/package/${PACKAGE_NAME}/${PACKAGE_NAME}.mk"

update_hash x86_64
update_hash armhf
