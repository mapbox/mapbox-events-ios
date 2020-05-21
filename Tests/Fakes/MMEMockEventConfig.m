#import "MMEMockEventConfig.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "MMEEventConfigProviding.h"

@implementation MMEMockEventConfig

- (instancetype)init {
    return [self initWithStartupDelay:MMEStartupDelayDefault
                      eventFlushCount:MMEEventFlushCountDefault
                   eventFlushInterval:MMEEventFlushIntervalDefault
           identifierRotationInterval:MMEIdentifierRotationIntervalDefault
                 configUpdateInterval:MMEConfigurationUpdateIntervalDefault
                     lastConfigUpdate:[MMEDate dateWithDate:NSDate.distantPast]
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
                     eventFlushCount:(NSUInteger)eventFlushCount
                  eventFlushInterval:(NSUInteger)eventFlushInterval
          identifierRotationInterval:(NSTimeInterval)identifierRotationInterval
                configUpdateInterval:(NSTimeInterval)configUpdateInterval
                    lastConfigUpdate:(MMEDate*)lastConfigUpdate
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
        self.startupDelay = startupDelay;
        self.eventFlushCount = eventFlushCount;
        self.eventFlushInterval = eventFlushInterval;
        self.identifierRotationInterval = identifierRotationInterval;
        self.configUpdateInterval = configUpdateInterval;
        self.configUpdateDate = lastConfigUpdate;
        self.eventTag = eventTag;
        self.accessToken = accessToken;
        self.legacyUserAgentBase = legacyUserAgentBase;
        self.legacyHostSDKVersion = legacyHostSDKVersion;
        self.isChinaRegion = isChinaRegion;
        self.apiServiceURL = apiURL;
        self.eventsServiceURL = eventsURL;
        self.configServiceURL = configURL;
        self.userAgentString = userAgent;
        self.legacyUserAgentString = legacyUserAgent;
        self.isCollectionEnabled = isCollectionEnabled;
        self.isCollectionEnabledInSimulator = isCollectionEnabledInSimulator;
        self.isCollectionEnabledInBackground = isCollectionEnabledInBackground;
        self.backgroundStartupDelay = backgroundStartupDelay;
        self.backgroundGeofence = backgroundGeofence;
        self.certificateRevocationList = certificationRevocationList;
        self.certificatePinningConfig = certificatePinningConfig;
    }
    return self;
}

+ (instancetype)oneSecondConfigUpdate {
    return [[MMEMockEventConfig alloc] initWithStartupDelay:MMEStartupDelayDefault
                                            eventFlushCount:MMEEventFlushCountDefault
                                         eventFlushInterval:MMEEventFlushIntervalDefault
                                 identifierRotationInterval:MMEIdentifierRotationIntervalDefault
                                       configUpdateInterval:1
                                           lastConfigUpdate:[MMEDate dateWithDate:NSDate.distantPast]
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

@end
