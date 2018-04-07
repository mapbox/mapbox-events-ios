## Mapbox Mobile Events

[![Bitrise](https://www.bitrise.io/app/63d52d847cdb36db/status.svg?token=DDdEMfpVR8emhdGSgToskA&branch=master)](https://www.bitrise.io/app/63d52d847cdb36db)

We use telemetry from all Mapbox SDKs to improve our map, directions, travel times, and search. We collect anonymous data about how users interact with the map to help developers build better location based applications.

Location telemetry is critical to improving the map. We use the data to discover missing roads, determine turn restrictions, build speed profiles, and improve OpenStreetMap.

Installation
----------
#### Using CocoaPods
1. To install Mapbox Mobile Events using CocoaPods:
  1. Create a Podfile with the following specification:  `pod 'MapboxMobileEvents'`
2. Run `pod repo update && pod install` and open the resulting Xcode workspace in your command line.

#### Using Carthage
1. Create a Cartfile with the following dependency: `github "mapbox/mapbox-events-ios"`
2. Run `carthage update --platform iOS`  to build just the iOS dependencies.
3. Follow the rest of Carthage’s iOS integration instructions. Your application target’s Embedded Frameworks should include MapboxMobileEvents.framework.

#### Using Pre-built binary
1. Download static binary from the latest release.
2. Drag MapboxMobileEvents.framework to your Embedded Binaries in General under your project file. Be sure to tick Copy items if needed.


Usage
----------

#### Add location authorization to plist

!["Privacy - Always and When In Use Usage Description" and "Privacy - Location When In Use Usage Description" are required.](https://d2mxuefqeaa7sj.cloudfront.net/s_BE0FC62A5A32FF041F5E19F0C9C4AD97FD9686B384F6CFD20A31A729F756E969_1522682906337_Location+Permissions.png)

#### Singleton Use

Import `MapboxMobileEvents` into the `AppDelegate` class of your project

    import UIKit
    import MapboxMobileEvents
    
    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {

initialize the singleton with your access token, user agent base, and version number.

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      MMEEventsManager.shared().initialize(withAccessToken: "access-token", userAgentBase: "user-agent", hostSDKVersion: "1.0.0")
      MMEEventsManager.shared().sendTurnstileEvent()
      
      return true
    }
#### Distinct Instance

Alternatively, it’s possible to use a distinct instance instead of the singleton.

Import MapboxMobileEvents into your project

    import MapboxMobileEvents

Initialize the MMEEventsManager instance

    let distinctInstance = MMEEventsManager()
            distinctInstance.initialize(withAccessToken: "access-token", userAgentBase: "user-agent", hostSDKVersion: "1.0.0")
            distinctInstance.sendTurnstileEvent()

#### Turnstile Event

`sendTurnstileEvent` allows us to track MAU (Monthly Active Users) on the application.
