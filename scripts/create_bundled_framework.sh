#!/bin/bash

# Script to create a submodule (inside a parent framework) for when the events library is 
# linked statically with the parent framework.
# The top level modulemap should look something like:
#
#   <existing module definition>
#
#   framework module MapboxMobileEvents {
#       framework module MapboxMobileEventsSubmodule {
#	        umbrella header "MapboxMobileEvents.h"    
#	        module * { export * }
#	    }
#   }

MAPBOX_EVENTS_IOS_PATH="$1"
FRAMEWORKS_PATH="$2"
FRAMEWORK_NAME="$3"

if [ -z "$FRAMEWORK_NAME" ] ; then
    >&2 echo "Usage: create_bundled_framework.sh <path-to-mapbox-events-ios> <path-to-output-dir> <name-of-bundled-framework>"
    exit 1
fi

# Headers
HEADERS_DIR=${FRAMEWORKS_PATH}/${FRAMEWORK_NAME}.framework/Headers

mkdir -p ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/MapboxMobileEvents.h ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/MMEEventsManager.h ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/MMEConstants.h ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/MMEEvent.h ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/MMETypes.h ${HEADERS_DIR}
cp ${MAPBOX_EVENTS_IOS_PATH}/MapboxMobileEvents/Categories/NSUserDefaults+MMEConfiguration.h ${HEADERS_DIR}

# Module map
MODULES_DIR=${FRAMEWORKS_PATH}/${FRAMEWORK_NAME}.framework/Modules
mkdir -p ${MODULES_DIR}

cat << EOF > ${MODULES_DIR}/${FRAMEWORK_NAME}.modulemap
framework module ${FRAMEWORK_NAME} {
	umbrella header "MapboxMobileEvents.h"    
	export_as MapboxMobileEvents
	module * { export * }
}
EOF
