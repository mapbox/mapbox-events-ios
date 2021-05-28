#!/usr/bin/env sh
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/../.."

if [ -z `which xcodegen` ]; then
    brew install xcodegen
fi

PODSPEC_FILE="MapboxMobileEvents.podspec"
XCFRAMEWORK_FILE="MapboxMobileEvents.zip"

pushd "${ROOT_DIR}"

# Replace remote podspec source with a zip-file served locally
LOCAL_ZIP="    :http => 'file:' + __dir__ + '\/build\/artifacts\/zip\/${XCFRAMEWORK_FILE}'"
sed -i '' "s/.*:http.*/${LOCAL_ZIP}/g" "${ROOT_DIR}/${PODSPEC_FILE}"

pushd "${ROOT_DIR}/Tests/Integration/CocoaPods"

xcodegen generate
bundle install
bundle exec pod install
xcodebuild -workspace PodInstall.xcworkspace -scheme PodInstall -destination 'platform=iOS Simulator,name=iPhone 11,OS=latest' build

git restore "${ROOT_DIR}/${PODSPEC_FILE}"

popd
