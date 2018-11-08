#!/usr/bin/env bash

set -e
set -o pipefail

npm install

# Track overall library size
scripts/check_binary_size.js "build/namespace/mapbox-events-ios-static/libMapboxEvents.a" "iOS Static"
scripts/check_binary_size.js "build/mapbox-events-ios-static.zip"                         "iOS ZIP"
