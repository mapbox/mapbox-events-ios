## Mapbox Mobile Events

[![Bitrise](https://app.bitrise.io/app/63d52d847cdb36db/status.svg?token=DDdEMfpVR8emhdGSgToskA&branch=master)](https://www.bitrise.io/app/63d52d847cdb36db)
![codecov](https://codecov.io/gh/mapbox/mapbox-events-ios/branch/master/graph/badge.svg)

### Dependancies

- [TrustKit](https://github.com/datatheorem/TrustKit) — provides SSL certificate pinning support 

### Dependants

- [MapBox Maps SDK](https://github.com/mapbox/mapbox-gl-native/)
- [MapBox Navigation SDK](https://github.com/mapbox/mapbox-navigation-ios/)
- [MapBox Vision SDK](https://github.com/mapbox/mapbox-vision-ios)
- [MapBox ReactNative SDK](https://github.com/mapbox/react-native-mapbox-gl)

### Quick Start

Include `MapboxMobileEvents.framework` in your application, in the application delegate's  `…didFinishLaunching…` method, add:

    MMEventsManager* manager = [MMEventsManager.alloc 
        initilizeWithAccessToken:@"your-mapbox-token" 
        userAgentBase:@"user-agent-string"
        hostSDKVersion:@"1.0.0"];
    manager.delegate = self;
    manager.isMetricsEnabledInSimulator = YES;
    manager.isDebugLoggingEnabled = (DEBUG ? YES : NO);
    manager.initilize(withAccessToken:@"your token kere")
    [manager sendTurnstileEvents];

Or, in Swift:
  
    /// declare this in your app delegate class
    var eventsManager: MMEEventsManager { return appDelegate.eventsManager }
    
    /// in …didFinishLaunching…
    eventsManager.isMetricsEnabledInSimulator = true
    eventsManager.isDebugLoggingEnabled = (DEBUG ? true : false)
    eventsManager.initialize(withAccessToken: "your-mapbox-token", userAgentBase: "user-agent-string", hostSDKVersion: "1.0.0")
    eventsManager.sendTurnstileEvent()

The `userAgentBase` and `hostSDKVersion` strings are used to build the `UserAgent:` header for event reports.

### Change Log

- v0.8.1 — Fix for some events not reacing the server, and duplication when flushing
- v0.8.0 — 
