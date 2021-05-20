#!/usr/bin/env bash
# This script creates MapboxMobileEvents artifacts

set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/.."

echo ${ROOT_DIR}

# cleanup artifacts folder
rm -rf $ROOT_DIR/build/artifacts

# build iOS .frameworks
xcodebuild archive \
        -archivePath ${ROOT_DIR}/build/artifacts/frameworks/iOS \
        -project ${ROOT_DIR}/MapboxMobileEvents.xcodeproj \
        -scheme MapboxMobileEvents \
        -destination="iOS" \
        -sdk iphoneos \
        -UseModernBuildSystem=YES \
        -derivedDataPath ${ROOT_DIR}/build/derivedDataPath/iOS \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        SUPPORTS_MACCATALYST=NO \
        -configuration Release

# build Catalyst .framework
xcodebuild archive \
        -archivePath ${ROOT_DIR}/build/artifacts/frameworks/iOS-Catalyst \
        -project ${ROOT_DIR}/MapboxMobileEvents.xcodeproj \
        -scheme MapboxMobileEvents \
        -destination="iOS" \
        -UseModernBuildSystem=YES \
        -derivedDataPath ${ROOT_DIR}/build/derivedDataPath/iOS-Catalyst \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        SUPPORTS_MACCATALYST=YES \
        -configuration Release

# build iOS Simulator .framework
xcodebuild archive \
        -archivePath ${ROOT_DIR}/build/artifacts/frameworks/iOS-Simulator \
        -project ${ROOT_DIR}/MapboxMobileEvents.xcodeproj \
        -scheme MapboxMobileEvents \
        -destination="iOS Simulator" \
        -sdk iphonesimulator \
        -UseModernBuildSystem=YES \
        -derivedDataPath ${ROOT_DIR}/build/derivedDataPath/iOS-Simulator \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        SUPPORTS_MACCATALYST=YES \
        -configuration Release

# build .xcframework
xcodebuild \
    -create-xcframework \
    -framework "${ROOT_DIR}/build/artifacts/frameworks/iOS.xcarchive/Products/Library/Frameworks/MapboxMobileEvents.framework" \
        -debug-symbols "${ROOT_DIR}/build/artifacts/frameworks/iOS.xcarchive/dSYMs/MapboxMobileEvents.framework.dSYM" \
    -framework "${ROOT_DIR}/build/artifacts/frameworks/iOS-Catalyst.xcarchive/Products/Library/Frameworks/MapboxMobileEvents.framework" \
        -debug-symbols "${ROOT_DIR}/build/artifacts/frameworks/iOS-Catalyst.xcarchive/dSYMs/MapboxMobileEvents.framework.dSYM" \
    -framework "${ROOT_DIR}/build/artifacts/frameworks/iOS-Simulator.xcarchive/Products/Library/Frameworks/MapboxMobileEvents.framework" \
        -debug-symbols "${ROOT_DIR}/build/artifacts/frameworks/iOS-Simulator.xcarchive/dSYMs/MapboxMobileEvents.framework.dSYM" \
    -output "${ROOT_DIR}/build/artifacts/frameworks/MapboxMobileEvents.xcframework"

# zip artifacts
mkdir -p ${ROOT_DIR}/build/artifacts/zip
ZIPDIR=${ROOT_DIR}/build/artifacts/zip

pushd ${ROOT_DIR}/build/artifacts/frameworks/iOS.xcarchive/Products/Library/Frameworks
zip --symlinks -r "${ZIPDIR}/MapboxMobileEvents-ios.zip" MapboxMobileEvents.framework
popd

pushd ${ROOT_DIR}/build/artifacts/frameworks
zip --symlinks -r "${ZIPDIR}/MapboxMobileEvents.zip" MapboxMobileEvents.xcframework
popd
