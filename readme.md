# Mapbox Mobile Events

[![Bitrise](https://app.bitrise.io/app/63d52d847cdb36db/status.svg?token=DDdEMfpVR8emhdGSgToskA&branch=master)](https://www.bitrise.io/app/63d52d847cdb36db)
![codecov](https://codecov.io/gh/mapbox/mapbox-events-ios/branch/master/graph/badge.svg)

The Mapbox Mobile Events SDK collects [anonymous data](https://www.mapbox.com/telemetry/) about the map and device location to continuously update and improve your maps.

### Dependancies

- [TrustKit](https://github.com/datatheorem/TrustKit) — provides SSL certificate pinning support 

### Dependents

- [Mapbox Maps SDK](https://github.com/mapbox/mapbox-gl-native/)
- [Mapbox Navigation SDK](https://github.com/mapbox/mapbox-navigation-ios/)
- [Mapbox Vision SDK](https://github.com/mapbox/mapbox-vision-ios)
- [Mapbox ReactNative SDK](https://github.com/mapbox/react-native-mapbox-gl)

### Quick Start

Include `MapboxMobileEvents.framework` in your application, in the application delegate's  `…didFinishLaunching…` method, add:

    MMEventsManager *manager = [MMEventsManager.alloc 
        initilizeWithAccessToken:@"your-mapbox-token" 
        userAgentBase:@"user-agent-string"
        hostSDKVersion:@"1.0.0"];
    manager.delegate = self;
    manager.isMetricsEnabledInSimulator = YES;
    manager.isDebugLoggingEnabled = (DEBUG ? YES : NO);
    [manager sendTurnstileEvent];

Or, in Swift:
  
    var eventsManager = MMEEventsManager()
    eventsManager.isMetricsEnabledInSimulator = true
    eventsManager.isDebugLoggingEnabled = (DEBUG ? true : false)
    eventsManager.initialize(withAccessToken: "your-mapbox-token", userAgentBase: "user-agent-string", hostSDKVersion: "1.0.0")
    eventsManager.sendTurnstileEvent()

### Testing

Test cases are written using [Cedar](https://github.com/cedarbdd/cedar), to run the test in `Xcode` using `Command-U` you'll need to install the framework:

    # install carthage
    brew install carthage
    
    # bootstrap the project
    cd $PROJECT_DIR
    carthage bootstrap
