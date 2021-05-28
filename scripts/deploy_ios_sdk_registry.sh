#!/usr/bin/env bash
# This script deploys MapboxMobileEvents SDK for iOS to SDK Registry
# <artifacts_dir>/MapboxMobileEvents.zip (archive containing MapboxMobileEvents.xcframework)
# <artifacts_dir>/MapboxMobileEvents-ios.zip (archive containing MapboxMobileEvents.framework)

set -eo pipefail

if [ "$IOS_DEPLOY_DRYRUN" != "false" ]; then
    DRYRUN=--dryrun
else
    DRYRUN=
fi

if [[ $# -lt 2 ]] ; then
    echo 'Script expects two arguments'
    echo 'Usage: deploy_ios_sdk_registry.sh <tag> <artifacts_dir>'
    exit 1
fi

VERSION_TAG=$1
VERSION=${VERSION_TAG#v}

ARTIFACTS_DIR="$2"

ZIP_XCFRAMEWORK_FILE="MapboxMobileEvents.zip"
ZIP_FRAMEWORK_FILE="MapboxMobileEvents-ios.zip"

ZIP_XCFRAMEWORK="${ARTIFACTS_DIR}/${ZIP_XCFRAMEWORK_FILE}"
ZIP_FRAMEWORK="${ARTIFACTS_DIR}/${ZIP_FRAMEWORK_FILE}"

if [ ! -f "${ZIP_XCFRAMEWORK}" ]; then
    echo "${ZIP_XCFRAMEWORK} not found"
    exit 1
fi

if [ ! -f "${ZIP_FRAMEWORK}" ]; then
    echo "${ZIP_FRAMEWORK} not found"
    exit 1
fi

if [ -z `which aws` ]; then
    brew install awscli
fi

echo "Deploying…"
aws s3 cp ${DRYRUN} ${ZIP_XCFRAMEWORK} s3://mapbox-api-downloads-production/v2/mapbox-events-ios/releases/ios/${VERSION}/packages/${ZIP_XCFRAMEWORK_FILE}
aws s3 cp ${DRYRUN} ${ZIP_FRAMEWORK} s3://mapbox-api-downloads-production/v2/mapbox-events-ios/releases/ios/${VERSION}/packages/${ZIP_FRAMEWORK_FILE}
