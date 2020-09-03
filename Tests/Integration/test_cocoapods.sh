#!/usr/bin/env sh
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/../.."
pushd "${ROOT_DIR}/Tests/Integration/CocoaPods"

if [ -z `which xcodegen` ]; then
    brew install xcodegen
fi

xcodegen generate
bundle install
bundle exec pod install
xcodebuild -workspace PodInstall.xcworkspace -scheme PodInstall -destination 'platform=iOS Simulator,name=iPhone 11,OS=latest' build

popd
