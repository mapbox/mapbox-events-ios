#!/usr/bin/env bash
# This script creates MapboxMobileEvents artifacts

set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/.."

ARTIFACTS_DIR="$ROOT_DIR/build/artifacts"
echo ${ARTIFACTS_DIR}

# cleanup artifacts folder
rm -rf $ARTIFACTS_DIR

# build iOS .frameworks
IOS_ARCHIVE_DIR="${ARTIFACTS_DIR}/frameworks/iOS.xcarchive"
xcodebuild archive \
        -archivePath "${IOS_ARCHIVE_DIR}" \
        -project "${ROOT_DIR}/MapboxMobileEvents.xcodeproj" \
        -scheme MapboxMobileEvents \
        -destination "generic/platform=iOS"\
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO

# build Catalyst .framework
IOS_CATALYST_ARCHIVE_DIR="${ARTIFACTS_DIR}/frameworks/iOS-Catalyst.xcarchive"
xcodebuild archive \
        -archivePath "${IOS_CATALYST_ARCHIVE_DIR}" \
        -project "${ROOT_DIR}/MapboxMobileEvents.xcodeproj" \
        -scheme MapboxMobileEvents \
        -destination "platform=macOS,variant=Mac Catalyst" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO

# build iOS Simulator .framework
IOS_SIMULATOR_ARCHIVE_DIR="${ARTIFACTS_DIR}/frameworks/iOS-Simulator.xcarchive"
xcodebuild archive \
        -archivePath "${IOS_SIMULATOR_ARCHIVE_DIR}" \
        -project "${ROOT_DIR}/MapboxMobileEvents.xcodeproj" \
        -scheme MapboxMobileEvents \
        -destination "generic/platform=iOS Simulator" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO

XCBUILD_ARGS="-create-xcframework"

function appendFrameworkArgs() {
    ARCHIVE_DIR=$1

    XCBUILD_ARGS+=" -framework ${ARCHIVE_DIR}/Products/Library/Frameworks/MapboxMobileEvents.framework"
    XCBUILD_ARGS+=" -debug-symbols ${ARCHIVE_DIR}/dSYMs/MapboxMobileEvents.framework.dSYM"
    for BCSYMBOLMAP in $(find ${ARCHIVE_DIR}/BCSymbolMaps -type f -name "*.bcsymbolmap")
    do 
        XCBUILD_ARGS+=" -debug-symbols ${BCSYMBOLMAP}"
    done
}

appendFrameworkArgs "${IOS_ARCHIVE_DIR}"
appendFrameworkArgs "${IOS_CATALYST_ARCHIVE_DIR}"
appendFrameworkArgs "${IOS_SIMULATOR_ARCHIVE_DIR}"

XCBUILD_ARGS+=" -output ${ARTIFACTS_DIR}/frameworks/MapboxMobileEvents.xcframework"

# build .xcframework
xcodebuild ${XCBUILD_ARGS[@]}

# zip artifacts
mkdir -p "${ARTIFACTS_DIR}/zip"
ZIPDIR="${ARTIFACTS_DIR}/zip"

pushd ${ARTIFACTS_DIR}/frameworks/iOS.xcarchive/Products/Library/Frameworks
cp "${ROOT_DIR}/LICENSE.md" .
zip --symlinks -r "${ZIPDIR}/MapboxMobileEvents-ios.zip" MapboxMobileEvents.framework LICENSE.md
popd

pushd ${ARTIFACTS_DIR}/frameworks
cp "${ROOT_DIR}/LICENSE.md" .
zip --symlinks -r "${ZIPDIR}/MapboxMobileEvents.zip" MapboxMobileEvents.xcframework LICENSE.md
popd
