## External frameworks

**Cedar.xcframework**

This a legacy dependency needed only for UnitTests in `MapboxMobileEventsCedarTests`. Theoretically those tests could be rewritten using `XCTest` if needed.
If there would be a need to rebuild this xcframework source is located in this [public repository](https://github.com/cedarbdd/cedar).
In order to create a proper xcframework you should use `Cedar-iOS` target from `Cedar.xcodeproj`.
1. Set the development target to iOS 9.0+ as otherwise you'll get `libarclite` build error.
2. Build the target for `iOS` and `iOS Simulator` destinations.
3. Use `xcodebuild -create-xcframework -framework Release-iphoneos/Cedar.framework -framework Release-iphonesimulator/Cedar.framework -output Cedar.xcframework` to produce XCFramework.