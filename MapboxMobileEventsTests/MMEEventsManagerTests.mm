#import <Cedar/Cedar.h>
#import "MMEEventsManager.h"
#import "MMEConstants.h"
#import "MMEUniqueIdentifier.h"
#import "MMEEventsConfiguration.h"
#import "MMENSDateWrapper.h"
#import "MMELocationManager.h"
#import "MMEAPIClient.h"
#import "MMETimerManager.h"
#import "MMETimerManagerFake.h"
#import "MMEAPIClientFake.h"
#import "MMECommonEventData.h"
#import "MMEUIApplicationWrapperFake.h"
#import "CLLocation+MMEMobileEvents.h"
#import "MMEUIApplicationWrapper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic) MMEEventsConfiguration *configuration;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) MMENSDateWrapper *dateWrapper;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

static CLLocation * location() {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(10, 10);
    CLLocationDistance altitude = 100;
    CLLocationAccuracy horizontalAccuracy = 42;
    CLLocationAccuracy verticalAccuracy = 24;
    CLLocationDirection course = 99;
    CLLocationSpeed speed = 102;
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
    return [[CLLocation alloc] initWithCoordinate:coordinate
                                         altitude:altitude
                               horizontalAccuracy:horizontalAccuracy
                                 verticalAccuracy:verticalAccuracy
                                           course:course
                                            speed:speed
                                        timestamp:timestamp];
}

SPEC_BEGIN(MMEEventsManagerSpec)

describe(@"MMEEventsManager", ^{
    
    __block MMEEventsManager *eventsManager;
    __block MMENSDateWrapper *dateWrapper;
    
    beforeEach(^{
        dateWrapper = [[MMENSDateWrapper alloc] init];
        eventsManager = [MMEEventsManager sharedManager];
        eventsManager.locationManager = nice_fake_for(@protocol(MMELocationManager));
        
        [eventsManager.eventQueue removeAllObjects];
        
        MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
        configuration.eventFlushCountThreshold = 1000;
        eventsManager.configuration = configuration;
    });
    
    it(@"sets common event data", ^{
        eventsManager.commonEventData should_not be_nil;
    });
    
    describe(@"- pauseOrResumeMetricsCollectionIfRequired", ^{
        
        context(@"when the location manager authorization is set to when in use, metrics enabled is false, and events are queued", ^{
            __block MMEUIApplicationWrapperFake *applicationFake;
            __block MMEAPIClientFake *apiClientWrapperFake;
            
            beforeEach(^{
                spy_on([CLLocationManager class]);
                [CLLocationManager class] stub_method(@selector(authorizationStatus)).and_return(kCLAuthorizationStatusAuthorizedWhenInUse);

                applicationFake = [[MMEUIApplicationWrapperFake alloc] init];
                spy_on(applicationFake);
                applicationFake stub_method(@selector(applicationState)).and_return(UIApplicationStateBackground);
                eventsManager.application = applicationFake;
                
                applicationFake.backgroundTaskIdentifier = 42;
                
                eventsManager.metricsEnabledForInUsePermissions = NO;
                
                apiClientWrapperFake = [[MMEAPIClientFake alloc] init];
                spy_on(apiClientWrapperFake);
                apiClientWrapperFake stub_method(@selector(accessToken)).and_return(@"access-token");
                eventsManager.apiClient = apiClientWrapperFake;
                
                eventsManager.paused = NO;
                [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                
                [eventsManager pauseOrResumeMetricsCollectionIfRequired];
            });
            
            afterEach(^{
                eventsManager.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            });
            
            it(@"tells the application to begin a background task", ^{
                eventsManager.application should have_received(@selector(beginBackgroundTaskWithExpirationHandler:));
            });
            
            it(@"should post queued events", ^{
                apiClientWrapperFake should have_received(@selector(postEvents:completionHandler:));
            });
            
            it(@"should pause metrics collection", ^{
                eventsManager.paused should be_truthy;
            });
            
            context(@"when post events completion handler is called", ^{
                beforeEach(^{
                    [apiClientWrapperFake completePostingEventsWithError:nil];
                });
                
                it(@"should call endBackgroundTask on the application", ^{
                    eventsManager.application should have_received(@selector(endBackgroundTask:));
                });
            });
            
            context(@"when application background task has not expired and pauseOrResumeMetricsCollectionIfRequired is called again", ^{
                beforeEach(^{
                    [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                });
                
                it(@"does not receive end background task", ^{
                    applicationFake should_not have_received(@selector(endBackgroundTask:));
                });
            });
            
            context(@"when application background task has expired", ^{
                
                beforeEach(^{
                    [applicationFake executeBackgroundTaskExpirationWithCompletionHandler];
                });
                
                it(@"does receive end background task", ^{
                    applicationFake should have_received(@selector(endBackgroundTask:)).with(applicationFake.backgroundTaskIdentifier);
                });
            });
        });
        
        context(@"when the event manager is paused", ^{
            beforeEach(^{
                eventsManager.paused = YES;
            });
            
            context(@"when metrics are enabled", ^{
                beforeEach(^{
                    eventsManager.metricsEnabledInSimulator = YES;
                    [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                });
                
                it(@"changes its state to not paused", ^{
                    eventsManager.paused should be_falsy;
                });
                
                it(@"tells its location manager to start updating location", ^{
                    eventsManager.locationManager should have_received(@selector(startUpdatingLocation));
                });
                
                context(@"when the events manager has been initialized", ^{
                    __block NSArray *locations;
                    
                    beforeEach(^{
                        [eventsManager initializeWithAccessToken:@"access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"host-sdk-version"];
                        spy_on(eventsManager.apiClient);
                        locations = @[location()];
                    });
                    
                    context(@"when the event count threshold has not yet been reached and a location event is received", ^{
                        beforeEach(^{
                            spy_on(eventsManager.timerManager);
                            
                            MMEEventsConfiguration *configuration = [[MMEEventsConfiguration alloc] init];
                            configuration.eventFlushCountThreshold = 2; // set a low value to make it easy to cross threshold in the test
                            eventsManager.configuration = configuration;
                            
                            eventsManager.delegate = nice_fake_for(@protocol(MMEEventsManagerDelegate));
                            
                            [eventsManager locationManager:nil didUpdateLocations:locations];
                        });
                        
                        it(@"should tell it's delegate that a location event has been received", ^{
                            eventsManager.delegate should have_received(@selector(locationManager:didUpdateLocations:)).with(eventsManager.locationManager).and_with(locations);
                        });
                        
                        it(@"tells the timer manager to start", ^{
                            eventsManager.timerManager should have_received(@selector(start));
                        });
                        
                        it(@"does not tell the api client to post", ^{
                            eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                        });
                        
                        context(@"when another location event is received and the event threshold is reached", ^{
                            beforeEach(^{
                                [eventsManager locationManager:nil didUpdateLocations:locations];
                            });
                            
                            it(@"tells the api client to post events with the location", ^{
                                CLLocation *location = locations.firstObject;
                                MMEMapboxEventAttributes *eventAttributes = @{MMEEventKeyCreated: [dateWrapper formattedDateStringForDate:[location timestamp]],
                                                                              MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                                                                              MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                                                                              MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                                                                              MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])};
                                
                                MMEEvent *expectedEvent1 = [MMEEvent locationEventWithAttributes:eventAttributes
                                                                              instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                                                                commonEventData:eventsManager.commonEventData];
                                MMEEvent *expectedEvent2 = [MMEEvent locationEventWithAttributes:eventAttributes
                                                                              instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                                                                commonEventData:eventsManager.commonEventData];
                                
                                eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:)).with(@[expectedEvent1, expectedEvent2]).and_with(Arguments::anything);
                            });
                            
                            it(@"tells the timer manager to cancel", ^{
                                eventsManager.timerManager should have_received(@selector(cancel));
                            });
                        });
                        
                        context(@"when no additional location events are received but the time threshold is reached", ^{
                            beforeEach(^{
                                MMETimerManagerFake *timerManager = [[MMETimerManagerFake alloc] init];
                                spy_on(timerManager);
                                timerManager.target = eventsManager;
                                timerManager.selector = @selector(flush);
                                [MMEEventsManager sharedManager].timerManager = timerManager;
                                [timerManager triggerTimer];
                            });
                            
                            it(@"tells the api client to post events with the location", ^{
                                CLLocation *location = locations.firstObject;
                                MMENSDateWrapper *dateWrapper = [[MMENSDateWrapper alloc] init];
                                MMEMapboxEventAttributes *eventAttributes = @{MMEEventKeyCreated: [dateWrapper formattedDateStringForDate:[location timestamp]],
                                                                              MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                                                                              MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                                                                              MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                                                                              MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])};
                                
                                MMEEvent *expectedEvent1 = [MMEEvent locationEventWithAttributes:eventAttributes
                                                                               instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                                                                 commonEventData:eventsManager.commonEventData];
                                
                                eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:)).with(@[expectedEvent1]).and_with(Arguments::anything);
                            });
                            
                            it(@"tells the timer manager to cancel", ^{
                                eventsManager.timerManager should have_received(@selector(cancel));
                            });
                        });
                    });
                });
            });
            
            context(@"when metrics are NOT enabled", ^{
                beforeEach(^{
                    eventsManager.metricsEnabledInSimulator = NO;
                    [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                });
                
                it(@"does NOT resume metrics", ^{
                    eventsManager.paused should be_truthy;
                });
                
                it(@"does not tell its location manager to start updating location", ^{
                    eventsManager.locationManager should_not have_received(@selector(startUpdatingLocation));
                });
            });
        });
        
        context(@"when the event manager is NOT paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when metrics are enabled", ^{
                beforeEach(^{
                    eventsManager.apiClient = nice_fake_for(@protocol(MMEAPIClient));
                    eventsManager.metricsEnabledInSimulator = YES;
                    [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                });
                
                it(@"does not change its state to paused", ^{
                    eventsManager.paused should be_falsy;
                });
                
                it(@"does not tell its api client to post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                });
                
                it(@"does not tell its location manager to stop updating location", ^{
                    eventsManager.locationManager should_not have_received(@selector(stopUpdatingLocation));
                });
            });
            
            context(@"when metrics are NOT enabled", ^{
                beforeEach(^{
                    eventsManager.apiClient = nice_fake_for(@protocol(MMEAPIClient));
                    eventsManager.metricsEnabledInSimulator = NO;
                });
                
                context(@"when an api token is set and there are events to flush", ^{
                    beforeEach(^{
                        eventsManager.apiClient stub_method(@selector(accessToken)).and_return(@"access-token");
                        [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                        [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                    });
                    
                    it(@"changes its state to paused", ^{
                        eventsManager.paused should be_truthy;
                    });
                    
                    it(@"tells its api client to post events", ^{
                        eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:));
                    });
                    
                    it(@"tells its location manager to stop updating location", ^{
                        eventsManager.locationManager should have_received(@selector(stopUpdatingLocation));
                    });
                });
            });
            
            context(@"when metrics low power mode is enabled", ^{
                beforeEach(^{
                    eventsManager.metricsEnabledInSimulator = YES;
                    eventsManager.apiClient = nice_fake_for(@protocol(MMEAPIClient));
                    eventsManager.apiClient stub_method(@selector(accessToken)).and_return(@"access-token");
                    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                    spy_on([NSProcessInfo processInfo]);
                    [NSProcessInfo processInfo] stub_method(@selector(isLowPowerModeEnabled)).and_return(YES);
                    [eventsManager pauseOrResumeMetricsCollectionIfRequired];
                });
                
                it(@"changes its state to paused", ^{
                    eventsManager.paused should be_truthy;
                });
                
                it(@"tells its api client to post events", ^{
                    eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:));
                });
                
                it(@"tells its location manager to stop updating location", ^{
                    eventsManager.locationManager should have_received(@selector(stopUpdatingLocation));
                });
            });
        });
    });
    
    describe(@"- flush", ^{
        
        beforeEach(^{
            MMEAPIClient *apiClient = nice_fake_for(@protocol(MMEAPIClient));
            eventsManager.apiClient = apiClient;
        });
        
        context(@"when the events manager is paused", ^{
            beforeEach(^{
                eventsManager.paused = YES;
            });
            
            it(@"does not tell the api client to post events", ^{
                eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
            });
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when no access token has been set", ^{
                beforeEach(^{
                    eventsManager.apiClient stub_method(@selector(accessToken)).and_return(nil);
                    [eventsManager flush];
                });
                
                it(@"does NOT tell the api client to post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                });
            });
            
            context(@"when an access token has been set", ^{
                beforeEach(^{
                    eventsManager.apiClient stub_method(@selector(accessToken)).and_return(@"access-token");
                });
                
                context(@"when there are no events in the queue", ^{
                    beforeEach(^{
                        eventsManager.eventQueue.count should equal(0);
                        [eventsManager flush];
                    });
                    
                    it(@"does NOT tell the api client to post events", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                    });
                });
                
                context(@"when there are events in the queue", ^{
                    beforeEach(^{
                        eventsManager.timerManager = [[MMETimerManager alloc] initWithTimeInterval:1000 target:eventsManager selector:@selector(flush)];
                        spy_on(eventsManager.timerManager);
                        [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                        [eventsManager flush];
                    });
                    
                    it(@"tells the api client to post events", ^{
                        eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:));
                    });
                    
                    it(@"tells its timer manager to cancel", ^{
                        eventsManager.timerManager should have_received(@selector(cancel));
                    });
                    
                    it(@"does nothing if flush is called again", ^{
                        [(id<CedarDouble>)eventsManager.apiClient reset_sent_messages];
                        [eventsManager flush];
                        eventsManager.apiClient should_not have_received(@selector(postEvents:completionHandler:));
                    });
                });
            });
        });
        
    });
    
    describe(@"- sendTurnstileEvent", ^{
        
        context(@"when next turnstile send date is nil", ^{
            beforeEach(^{
                eventsManager.nextTurnstileSendDate should be_nil;
            });
            
            describe(@"calling the method before setting up required variables", ^{
                beforeEach(^{
                    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                    spy_on(fakeAPIClient);
                    
                    fakeAPIClient.accessToken = @"access-token";
                    fakeAPIClient.userAgentBase = @"user-agent-base";
                    fakeAPIClient.hostSDKVersion = @"host-sdk-version";
                    
                    eventsManager.apiClient = fakeAPIClient;
                    
                    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
                    spy_on(commonEventData);
                    commonEventData.vendorId = @"vendor-id";
                    commonEventData.model = @"model";
                    commonEventData.iOSVersion = @"ios-version";
                    
                    eventsManager.commonEventData = commonEventData;
                });
                
                context(@"when the events manager's api client does not have an access token set", ^{
                    beforeEach(^{
                        eventsManager.apiClient stub_method(@selector(accessToken)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's api client does not have a user agent base set", ^{
                    beforeEach(^{
                        eventsManager.apiClient stub_method(@selector(userAgentBase)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's api client does not have a host sdk version set", ^{
                    beforeEach(^{
                        eventsManager.apiClient stub_method(@selector(hostSDKVersion)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a vendor id", ^{
                    beforeEach(^{
                        eventsManager.commonEventData stub_method(@selector(vendorId)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a model", ^{
                    beforeEach(^{
                        eventsManager.commonEventData stub_method(@selector(model)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
                
                context(@"when the events manager's common even data does not have a ios version", ^{
                    beforeEach(^{
                        eventsManager.commonEventData stub_method(@selector(iOSVersion)).and_return(nil);
                        [eventsManager sendTurnstileEvent];
                    });
                    
                    it(@"does not tell its api client to post the event", ^{
                        eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                    });
                });
            });
            
            context(@"when the events manager's api client is correctly configured", ^{
                beforeEach(^{
                    spy_on([NSDate class]);
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
                    [NSDate class] stub_method(@selector(date)).and_return(date);
                    
                    eventsManager.metricsEnabledInSimulator = NO;
                    
                    MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                    spy_on(fakeAPIClient);
                    
                    fakeAPIClient.accessToken = @"access-token";
                    fakeAPIClient.userAgentBase = @"user-agent-base";
                    fakeAPIClient.hostSDKVersion = @"host-sdk-version";
                    
                    eventsManager.apiClient = fakeAPIClient;
                    
                    [eventsManager sendTurnstileEvent];
                });
                
                it(@"tells its api client to post events", ^{
                    NSDictionary *turnstileEventAttributes = @{MMEEventKeyEvent: MMEEventTypeAppUserTurnstile,
                                                               MMEEventKeyCreated: [dateWrapper formattedDateStringForDate:[dateWrapper date]],
                                                               MMEEventKeyVendorID: eventsManager.commonEventData.vendorId,
                                                               MMEEventKeyDevice: eventsManager.commonEventData.model,
                                                               MMEEventKeyOperatingSystem: eventsManager.commonEventData.iOSVersion,
                                                               MMEEventSDKIdentifier: eventsManager.apiClient.userAgentBase,
                                                               MMEEventSDKVersion: eventsManager.apiClient.hostSDKVersion,
                                                               MMEEventKeyEnabledTelemetry: @NO};
                    MMEEvent *expectedEvent = [MMEEvent turnstileEventWithAttributes:turnstileEventAttributes];
                    
                    eventsManager.apiClient should have_received(@selector(postEvent:completionHandler:)).with(expectedEvent).and_with(Arguments::anything);
                });
            });
            
        });
        
        context(@"when next turnstile send date is not nil and event manager is correctly configured", ^{
            beforeEach(^{
                eventsManager.nextTurnstileSendDate = [NSDate dateWithTimeIntervalSince1970:1000];
                
                MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                spy_on(fakeAPIClient);
                fakeAPIClient.accessToken = @"access-token";
                fakeAPIClient.userAgentBase = @"user-agent-base";
                fakeAPIClient.hostSDKVersion = @"host-sdk-version";
                eventsManager.apiClient = fakeAPIClient;
                
                spy_on([NSDate class]);
            });
            
            afterEach(^{
                eventsManager.nextTurnstileSendDate = nil;
                stop_spying_on([NSDate class]);
            });

            context(@"when the current time is before the next turnstile send date", ^{
                beforeEach(^{
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:500];
                    [NSDate class] stub_method(@selector(date)).and_return(date);
                    
                    [eventsManager sendTurnstileEvent];
                });
                
                it(@"tells its api client to not post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                });
            });
            
            context(@"when the current time is after the next turnstile send date", ^{
                beforeEach(^{
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1001];
                    [NSDate class] stub_method(@selector(date)).and_return(date);
                    
                    [eventsManager sendTurnstileEvent];
                });
                
                it(@"tells its api client to post events", ^{
                    eventsManager.apiClient should have_received(@selector(postEvent:completionHandler:));
                });
            });
        });
        
    });
    
    describe(@"- enqueueEventWithName:attributes", ^{
        __block NSString *dateString;
        __block MMECommonEventData *commonEventData;
        __block NSDictionary *attributes;
        
        beforeEach(^{
            dateString = @"A nice date";
            spy_on(dateWrapper);
            dateWrapper stub_method(@selector(formattedDateStringForDate:)).and_return(dateString);
            eventsManager.dateWrapper = dateWrapper;
            
            commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"a nice vendor id";
            commonEventData.model = @"a nice model";
            commonEventData.iOSVersion = @"a nice ios version";
            commonEventData.scale = 42.0;
            eventsManager.commonEventData = commonEventData;
            
            attributes = @{@"attribute1": @"a nice attribute"};
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when a map tap event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapTap attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapTapEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    event should equal(expectedEvent);
                });
            });

            context(@"when a map drag end event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapDragEnd attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapDragEndEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a navigation event is pushed", ^{
                __block NSString * navigationEventName = @"navigation.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:navigationEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent navigationEventWithName:navigationEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    event should equal(expectedEvent);
                });
            });
            
            context(@"when an unknown event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:@"invalid" attributes:attributes];
                });
                
                it(@"does not queue the event", ^{
                    eventsManager.eventQueue.count should equal(0);
                });
            });
        });
    });
    
    describe(@"- enqueueEventWithName:", ^{
        __block NSString *dateString;
        __block MMECommonEventData *commonEventData;
        
        beforeEach(^{
            dateString = @"A nice date";
            spy_on(dateWrapper);
            dateWrapper stub_method(@selector(formattedDateStringForDate:)).and_return(dateString);
            eventsManager.dateWrapper = dateWrapper;
            
            commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"a nice vendor id";
            commonEventData.model = @"a nice model";
            commonEventData.iOSVersion = @"a nice ios version";
            commonEventData.scale = 42.0;
            eventsManager.commonEventData = commonEventData;
        });
        
        context(@"when the events manager is not paused", ^{
            beforeEach(^{
                eventsManager.paused = NO;
            });
            
            context(@"when a map load event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapLoadEventWithDateString:dateString commonEventData:commonEventData];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    
                    event should equal(expectedEvent);
                });
            });
        });
        
        context(@"when the events manager is paused", ^{
            beforeEach(^{
                eventsManager.paused = YES;
            });
            
            context(@"when a map load event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEEventTypeMapLoad];
                });
                
                it(@"has no event", ^{
                    eventsManager.eventQueue.count should equal(0);
                });
            });
        });
    });
});

SPEC_END
