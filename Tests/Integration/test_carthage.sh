#!/usr/bin/env sh
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/../.."
pushd "${ROOT_DIR}/Tests/Integration/Carthage"

if [ -z `which xcodegen` ]; then
     brew install xcodegen
fi

sed -i '' -e "s|@PATH@|file:///${ROOT_DIR}|g" "${ROOT_DIR}/Tests/Integration/Carthage/Cartfile"
xcodegen generate
carthage update --platform iOS --use-netrc
xcodebuild -project CarthageTest.xcodeproj -scheme CarthageTest -destination 'platform=iOS Simulator,name=iPhone 11,OS=latest' build

popd
