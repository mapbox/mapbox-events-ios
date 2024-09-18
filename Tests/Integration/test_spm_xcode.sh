#!/usr/bin/env sh
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/../.."
pushd "${ROOT_DIR}/Tests/Integration/SPMXcode"

if [ -z `which xcodegen` ]; then
     brew install xcodegen
fi

xcodegen
xcodebuild -project SPMXcode.xcodeproj -scheme SPMXcode build -destination='platform=iOS Simulator,name=iPhone 13,OS=15.5' CODE_SIGNING_ALLOWED=NO

popd
