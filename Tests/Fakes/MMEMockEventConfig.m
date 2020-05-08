#import "MMEMockEventConfig.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConstants.h"

@implementation MMEMockEventConfig

- (instancetype)init {
    return [self initWithStartupDelay:MMEStartupDelayDefault
                      eventFlushCount:MMEEventFlushCountDefault
                        flushInterval:MMEEventFlushIntervalDefault
           identifierRotationInterval:MMEIdentifierRotationIntervalDefault
                 configUpdateInterval:MMEConfigurationUpdateIntervalDefault
                             eventTag:@"42"
                          accessToken:@"access-token"
                  legacyUserAgentBase:@"user-agent-base"
                 legacyHostSDKVersion:@"1.0"
                        isChinaRegion:NO
                               apiURL:[NSURL URLWithString:MMEAPIClientBaseAPIURL]
                            eventsURL:[NSURL URLWithString:MMEAPIClientBaseEventsURL]
                            configURL:[NSURL URLWithString:MMEAPIClientBaseConfigURL]
                            userAgent:@"<UserAgent>"
                      legacyUserAgent:@"<LegacyUserAgent>"
                  isCollectionEnabled:YES
       isCollectionEnabledInSimulator:YES
      isCollectionEnabledInBackground:YES
               backgroundStartupDelay:MMEBackgroundStartupDelayDefault
                   backgroundGeofence:MMEBackgroundGeofenceDefault
            certificateRevocationList:@[]
             certificatePinningConfig:@{}];
}

- (instancetype)initWithStartupDelay:(NSTimeInterval)startupDelay
                     eventFlushCount:(NSUInteger)flushCount
                       flushInterval:(NSUInteger)flushInterval
          identifierRotationInterval:(NSTimeInterval)identifierRotationInterval
                configUpdateInterval:(NSTimeInterval)configUpdateInterval
                            eventTag:(NSString*)eventTag
                         accessToken:(NSString*)accessToken
                 legacyUserAgentBase:(NSString*)legacyUserAgentBase
                legacyHostSDKVersion:(NSString*)legacyHostSDKVersion
                       isChinaRegion:(BOOL)isChinaRegion
                          apiURL:(NSURL*)apiURL
                    eventsURL:(NSURL*)eventsURL
                           configURL:(NSURL*)configURL
                           userAgent:(NSString*)userAgent
                     legacyUserAgent:(NSString*)legacyUserAgent
                 isCollectionEnabled:(BOOL)isCollectionEnabled
      isCollectionEnabledInSimulator:(BOOL)isCollectionEnabledInSimulator
     isCollectionEnabledInBackground:(BOOL)isCollectionEnabledInBackground
              backgroundStartupDelay:(NSTimeInterval)backgroundStartupDelay
                  backgroundGeofence:(CLLocationDistance)backgroundGeofence
           certificateRevocationList:(NSArray<NSString*>*)certificationRevocationList
            certificatePinningConfig:(NSDictionary<NSString*, NSArray<NSString*>*>*)certificatePinningConfig {

    if (self = [super init]) {
        _mme_startupDelay = startupDelay;
        _mme_eventFlushCount = flushCount;
        _mme_eventFlushInterval = flushInterval;
        _mme_identifierRotationInterval = identifierRotationInterval;
        _mme_configUpdateInterval = configUpdateInterval;
        _mme_eventTag = [eventTag copy];
        _mme_accessToken = [accessToken copy];
        _mme_legacyUserAgentBase = [legacyUserAgentBase copy];
        _mme_legacyHostSDKVersion = [legacyHostSDKVersion copy];
        _mme_isCNRegion = isChinaRegion;
        _mme_APIServiceURL = [apiURL copy];
        _mme_eventsServiceURL = [eventsURL copy];
        _mme_configServiceURL = [configURL copy];
        _mme_userAgentString = [userAgent copy];
        _mme_legacyUserAgentString = [legacyUserAgent copy];
        _mme_isCollectionEnabled = isCollectionEnabled;
        _mme_isCollectionEnabledInSimulator = isCollectionEnabledInSimulator;
        _mme_isCollectionEnabledInBackground = isCollectionEnabledInBackground;
        _mme_backgroundStartupDelay = backgroundStartupDelay;
        _mme_backgroundGeofence = backgroundGeofence;
        _mme_certificateRevocationList = [certificationRevocationList copy];
        _mme_certificatePinningConfig = [certificatePinningConfig copy];
    }
    return self;
}

@end
