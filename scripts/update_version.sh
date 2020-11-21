#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

if [ $# -eq 0 ]; then
    echo "Usage: v<semantic version>"
    exit 1
fi

SEM_VERSION=$1
SEMVER_REGEX="^v([0-9]*)\.([0-9]*)\.([0-9]*)-?(.?)[a-zA-Z]*\.?([0-9]*)"

if [[ ! $SEM_VERSION =~ $SEMVER_REGEX ]]; then
    echo "${SEM_VERSION} is not a valid semantic version"
    exit 1
fi

SHORT_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"

step "Version ${SEM_VERSION}"

step "Updating Xcode targets to version ${SHORT_VERSION}…"

xcrun agvtool bump -all
xcrun agvtool new-marketing-version "${SHORT_VERSION}"

FRAMEWORK_PLIST=Sources/MapboxMobileEvents/Info.plist

# remove the leading 'v' from the SEM_VERSION
step "Adding ${SEM_VERSION:1} to ${FRAMEWORK_PLIST}"

plutil -replace "MGLSemanticVersionString" -string "${SEM_VERSION:1}" "${FRAMEWORK_PLIST}"
