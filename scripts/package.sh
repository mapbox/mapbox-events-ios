#!/usr/bin/env bash

set -e
set -o pipefail
set -u

DERIVED_DATA='build'
PRODUCTS=${DERIVED_DATA}/Build/Products
OUTPUT=build/namespace/static
SCHEME='MapboxMobileEventsStatic'
BUILDTYPE=${BUILDTYPE:-Debug}
JOBS=`sysctl -n hw.ncpu`

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

# This is a modified version of: https://github.com/jverkoey/nimbus/blob/master/scripts/generate_namespace_header
function generate_namespace_header {
    path=build/namespace/header
    header=${path}/MMENamespacedDependencies.h
    prefix="MGL"
    mkdir -p $path && touch $header

    echo "Generating $header from $1"

    echo "// Namespaced Header

    #ifndef __NS_SYMBOL
    // We need to have multiple levels of macros here so that __NAMESPACE_PREFIX_ is
    // properly replaced by the time we concatenate the namespace prefix.
    #define __NS_REWRITE(ns, symbol) ns ## _ ## symbol
    #define __NS_BRIDGE(ns, symbol) __NS_REWRITE(ns, symbol)
    #define __NS_SYMBOL(symbol) __NS_BRIDGE($prefix, symbol)
    #endif

    " > $header

    echo "// Classes" >> $header
    nm $1 -j | sort | uniq | grep "^_OBJC_CLASS_\$_" | grep -v "\$_AGSGT" | grep -v "\$_CL" | grep -v "\$_NS" | grep -v "\$_UI" | sed -e 's/_OBJC_CLASS_\$_\(.*\)/#ifndef \1\'$'\n''#define \1 __NS_SYMBOL(\1)\'$'\n''#endif\'$'\n''/g' >> $header

    echo "// Functions" >> $header
    nm $1 | sort | uniq | grep " T " | cut -d' ' -f3 | grep -v "\$_NS" | grep -v "\$_UI" | sed -e 's/_\(.*\)/#ifndef \1\'$'\n''#define \1 __NS_SYMBOL(\1)\'$'\n''#endif\'$'\n''/g' >> $header


    echo "// Externs" >> $header
    nm $1 | sort | uniq | grep " D " | cut -d' ' -f3 | grep -v "\$_NS" | grep -v "\$_UI" | sed -e 's/_\(.*\)/#ifndef \1\'$'\n''#define \1 __NS_SYMBOL(\1)\'$'\n''#endif\'$'\n''/g' >> $header
    nm $1 | sort | uniq | grep " S " | cut -d' ' -f3 | grep -v "\$_NS" | grep -v ".eh" | grep -v "\$_UI" | grep -v "OBJC_" | sed -e 's/_\(.*\)/#ifndef \1\'$'\n''#define \1 __NS_SYMBOL(\1)\'$'\n''#endif\'$'\n''/g' >> $header
}

# Can build iphoneos (device) or iphonesimulator (simulator)
function build() {    
    xcodebuild \
        ONLY_ACTIVE_ARCH=NO \
        -project MapboxMobileEvents.xcodeproj \
        -scheme ${SCHEME} \
        -derivedDataPath ${DERIVED_DATA} \
        -configuration ${BUILDTYPE} \
        -jobs ${JOBS} \
        -sdk $1 build | xcpretty
}

function create_static_framework() {
    mkdir -p ${OUTPUT} && touch ${OUTPUT}/libMapboxEvents.a
    libtool -static -no_warning_for_no_symbols -o ${OUTPUT}/libMapboxEvents.a \
        ${PRODUCTS}/${BUILDTYPE}-iphoneos/libMapboxMobileEventsStatic.a \
        ${PRODUCTS}/${BUILDTYPE}-iphonesimulator/libMapboxMobileEventsStatic.a
}

step "[INFO] Cleaning build folder"
rm -rf build/*

step "Building binary using scheme ${SCHEME} for iphonesimulator"
build iphonesimulator

step "[INFO] Generating namespaced header"
generate_namespace_header $PRODUCTS/${BUILDTYPE}-iphonesimulator/libMapboxMobileEventsStatic.a
