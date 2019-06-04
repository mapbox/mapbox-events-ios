#import <Cedar/Cedar.h>
#import "MMEEventsManager.h"
#import "MMEConstants.h"
#import "MMEUniqueIdentifier.h"
#import "MMEEventsConfiguration.h"
#import "MMEDate.h"
#import "MMELocationManager.h"
#import "MMEAPIClient.h"
#import "MMETimerManager.h"
#import "MMEDispatchManagerFake.h"
#import "MMETimerManagerFake.h"
#import "MMEAPIClientFake.h"
#import "MMECommonEventData.h"
#import "MMEUIApplicationWrapperFake.h"
#import "CLLocation+MMEMobileEvents.h"
#import "CLLocationManager+MMEMobileEvents.h"
#import "MMEUIApplicationWrapper.h"
#import "MMEMetricsManager.h"
#import "MMEDateFakes.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;
using namespace Cedar::Doubles::Arguments;

@interface MMEEventsManager (Tests) <MMELocationManagerDelegate>

@property (nonatomic) NS_MUTABLE_ARRAY_OF(MMEEvent *) *eventQueue;
@property (nonatomic) MMEEventsConfiguration *configuration;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic) MMECommonEventData *commonEventData;
@property (nonatomic) id<MMELocationManager> locationManager;
@property (nonatomic) id<MMEAPIClient> apiClient;
@property (nonatomic) id<MMEUniqueIdentifer> uniqueIdentifer;
@property (nonatomic) MMETimerManager *timerManager;
@property (nonatomic) MMEDispatchManager *dispatchManager;
@property (nonatomic) NSDate *nextTurnstileSendDate;
@property (nonatomic) id<MMEUIApplicationWrapper> application;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (instancetype)initShared;
- (void)pushEvent:(MMEEvent *)event;

@end

#pragma mark -

@interface MMEEvent (Tests)
@property(nonatomic,retain) MMEDate *dateStorage;
@property(nonatomic,retain) NSDictionary *attributesStorage;

@end

#pragma mark -

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

#pragma mark -

SPEC_BEGIN(MMEEventsManagerSpec)

/* many of the tests use a manager which is not the shared manager,
   in normal operation clietns should not use the private initShared method used for testsing */
describe(@"MMEventsManager.sharedManager", ^{
    MMEEventsManager *shared = MMEEventsManager.sharedManager;
    MMEEventsManager *allocated = [MMEEventsManager.alloc init];

    it(@"", ^{
        shared should equal(allocated);
    });
});

describe(@"MMEEventsManager", ^{
    
    __block MMEEventsManager *eventsManager;
    __block MMEEventsConfiguration *configuration;
    __block MMEDispatchManagerFake *dispatchManager;

    beforeEach(^{
        dispatchManager = [[MMEDispatchManagerFake alloc] init];
        eventsManager = [MMEEventsManager.alloc initShared];

        eventsManager.dispatchManager = dispatchManager;
        eventsManager.locationManager = nice_fake_for(@protocol(MMELocationManager));

        [eventsManager.eventQueue removeAllObjects];

        configuration = [[MMEEventsConfiguration alloc] init];
        configuration.eventFlushCountThreshold = 1000;
        eventsManager.configuration = configuration;
    });

    it(@"sets common event data", ^{
        eventsManager.commonEventData should_not be_nil;
    });

    describe(@"-initializeWithAccessToken:userAgentBase:hostSDKVersion:", ^{
        NSBundle *bundle = [NSBundle mainBundle];

        beforeEach(^{
            spy_on(bundle);
        });

        afterEach(^{
            stop_spying_on(bundle);
        });

        context(@"when the custom events profile is set", ^{
            beforeEach(^{
                NSDictionary *infoDictionary = @{ @"MMEEventsProfile" : @"Custom" };
                bundle stub_method(@selector(infoDictionary)).and_return(infoDictionary);

                eventsManager = [MMEEventsManager.alloc initShared];
                eventsManager.dispatchManager = dispatchManager;

                [eventsManager initializeWithAccessToken:@"foo" userAgentBase:@"bar" hostSDKVersion:@"baz"];
            });

            it(@"should schedule the initialization work with a 10 second delay", ^{
                dispatchManager.delay should equal(10);
            });
        });

        context(@"when no fancy value is set", ^{
            beforeEach(^{
                eventsManager = [MMEEventsManager.alloc initShared];
                eventsManager.dispatchManager = dispatchManager;

                [eventsManager initializeWithAccessToken:@"foo" userAgentBase:@"bar" hostSDKVersion:@"baz"];
            });

            it(@"should schedule the initialization work without a delay", ^{
                dispatchManager.delay should equal(0);
            });
        });
    });

    describe(@"- setConfiguration", ^{
        beforeEach(^{
            eventsManager.configuration = [MMEEventsConfiguration configuration];
        });

        it(@"should set the radius for configuration", ^{
            eventsManager.configuration.locationManagerHibernationRadius should_not equal(0);
        });
        
        it(@"should set the eventFlushCountThreshold", ^{
            eventsManager.configuration.eventFlushCountThreshold should_not equal(0);
        });
        
        it(@"should set the eventFlushSecondsThreshold", ^{
            eventsManager.configuration.eventFlushSecondsThreshold should_not equal(0);
        });
        
        it(@"should set the instanceIdentifierRotationTimeInterval", ^{
            eventsManager.configuration.instanceIdentifierRotationTimeInterval should_not equal(0);
        });
    });
    
    describe(@"- setSkuId", ^{
        __block NSString *aNiceSkuId = @"42";
        
        beforeEach(^{
            [eventsManager initializeWithAccessToken:@"access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"host-version"];
        });
        
        it(@"shouldn't be set", ^{
            eventsManager.skuId should be_nil;
        });
        
        it(@"sets the skuId on the events manager", ^{
            [eventsManager setSkuId:aNiceSkuId];
            
            eventsManager.skuId should equal(aNiceSkuId);
        });
    });
    
    describe(@"- setAccessToken", ^{
        __block NSString *newAccessToken = @"new-access-token";
        
        beforeEach(^{
            [eventsManager initializeWithAccessToken:@"first-access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"host-version"];
            eventsManager.accessToken = newAccessToken;
        });
        
        it(@"sets the access token on the api client", ^{
            eventsManager.apiClient.accessToken should equal(newAccessToken);
        });
    });
    
    describe(@"- setBaseURL", ^{
        __block NSURL *testURL = [NSURL URLWithString:@"https://test.com"];
        
        beforeEach(^{
            [eventsManager initializeWithAccessToken:@"first-access-token" userAgentBase:@"user-agent-base" hostSDKVersion:@"host-version"];
            eventsManager.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            eventsManager.baseURL = testURL;
        });
        
        it(@"has the correct API client", ^{
            eventsManager.baseURL should equal(testURL);
        });
        
        context(@"when the url is reset with a nil value", ^{
            beforeEach(^{
                eventsManager.baseURL = nil;
            });
            
            it(@"has the default value", ^{
               eventsManager.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            });
        });
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
                    
                    context(@"when the events manager is re-initialized", ^{
                        __block NSString *capturedAccessToken;
                        __block MMEEventsManager *capturedEventsManager;
                        
                        beforeEach(^{
                            capturedEventsManager = eventsManager;
                            capturedAccessToken = eventsManager.accessToken;
                            [eventsManager initializeWithAccessToken:@"access-token-reinit" userAgentBase:@"user-agent-base" hostSDKVersion:@"host-sdk-version"];
                        });
                        
                        it(@"should not be re-initalized", ^{
                            eventsManager should equal(capturedEventsManager);
                        });
                        
                        it(@"should change the access token", ^{
                            eventsManager.accessToken should_not equal(capturedAccessToken);
                        });
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
                            eventsManager.delegate should have_received(@selector(eventsManager:didUpdateLocations:)).with(eventsManager).and_with(locations);
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
                                MMEMapboxEventAttributes *eventAttributes = @{
                                    MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                                    MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                                    MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                                    MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                                    MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
                                };
                                
                                MMEEvent *expectedEvent1 = [MMEEvent locationEventWithAttributes:eventAttributes
                                    instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                    commonEventData:eventsManager.commonEventData];
                                expectedEvent1.dateStorage = MMEDateFakes.earlier;

                                MMEEvent *expectedEvent2 = [MMEEvent locationEventWithAttributes:eventAttributes
                                    instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                    commonEventData:eventsManager.commonEventData];
                                expectedEvent2.dateStorage = MMEDateFakes.earlier;
                                
                                eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:)).with(@[expectedEvent1, expectedEvent2]).and_with(Arguments::anything);
                            });
                            
                            it(@"tells the timer manager to cancel", ^{
                                eventsManager.timerManager should have_received(@selector(cancel));
                            });
                        });
                        
                        context(@"when no additional events are received but the time threshold is reached", ^{
                            __block MMEEvent *telemetryMetricsEvent;
                            beforeEach(^{
                                telemetryMetricsEvent = [MMEEvent telemetryMetricsEventWithDateString:@"anicedate" attributes:@{}];
                                
                                spy_on([MMEMetricsManager sharedManager]);
                                [MMEMetricsManager sharedManager] stub_method(@selector(generateTelemetryMetricsEvent)).and_return(telemetryMetricsEvent);
                                
                                MMETimerManagerFake *timerManager = [[MMETimerManagerFake alloc] init];
                                spy_on(timerManager);
                                timerManager.target = eventsManager;
                                timerManager.selector = @selector(sendTelemetryMetricsEvent);
                                MMEEventsManager.sharedManager.timerManager = timerManager;
                                [timerManager triggerTimer];
                            });
                            
                            it(@"should attempt to post telemetryMetrics event", ^{
                                eventsManager.apiClient should have_received(@selector(postEvents:completionHandler:)).with(@[telemetryMetricsEvent]).and_with(Arguments::anything);
                            });
                        });
                        
                        context(@"when no additional location events are received but the time threshold is reached", ^{
                            beforeEach(^{
                                MMETimerManagerFake *timerManager = [[MMETimerManagerFake alloc] init];
                                spy_on(timerManager);
                                timerManager.target = eventsManager;
                                timerManager.selector = @selector(flush);
                                MMEEventsManager.sharedManager.timerManager = timerManager;
                                [timerManager triggerTimer];
                            });
                            
                            it(@"tells the api client to post events with the location", ^{
                                CLLocation *location = locations.firstObject;
                                MMEMapboxEventAttributes *eventAttributes = @{
                                    MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                                    MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                                    MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                                    MMEEventKeyAltitude: @([location mme_roundedAltitude]),
                                    MMEEventHorizontalAccuracy: @([location mme_roundedHorizontalAccuracy])
                                };
                                
                                MMEEvent *expectedEvent1 = [MMEEvent locationEventWithAttributes:eventAttributes
                                    instanceIdentifer:eventsManager.uniqueIdentifer.rollingInstanceIdentifer
                                    commonEventData:eventsManager.commonEventData];
                                expectedEvent1.dateStorage = MMEDateFakes.earlier;
                                
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
                    eventsManager.metricsEnabled = NO; // disable in simulator and on device
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
                    eventsManager.metricsEnabled = NO; // disable for simulator and real device
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
                    commonEventData.osVersion = @"ios-version";
                    
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
                        eventsManager.commonEventData stub_method(@selector(osVersion)).and_return(nil);
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
                    
                    eventsManager.metricsEnabled = NO; // on device or in simulator
                    
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
                                                               MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[NSDate date]],
                                                               MMEEventKeyVendorID: eventsManager.commonEventData.vendorId,
                                                               MMEEventKeyDevice: eventsManager.commonEventData.model,
                                                               MMEEventKeyOperatingSystem: eventsManager.commonEventData.osVersion,
                                                               MMEEventSDKIdentifier: eventsManager.apiClient.userAgentBase,
                                                               MMEEventSDKVersion: eventsManager.apiClient.hostSDKVersion,
                                                               MMEEventKeyEnabledTelemetry: @NO,
                                                               MMEEventKeyLocationEnabled: @([CLLocationManager locationServicesEnabled]),
                                                               MMEEventKeyLocationAuthorization: [CLLocationManager mme_authorizationStatusString],
                                                               MMEEventKeySkuId: eventsManager.skuId ?: [NSNull null]
                                                               };
                    MMEEvent *expectedEvent = [MMEEvent turnstileEventWithAttributes:turnstileEventAttributes];
                    expectedEvent.dateStorage = MMEDateFakes.earlier;

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
    
    describe(@"- sendTelemetryMetricsEvent", ^{
        context(@"when next telemetryMetrics send date is not nil and event manager is correctly configured", ^{
            beforeEach(^{
                MMEEvent *event = [MMEEvent mapTapEventWithDateString:@"a nice date" attributes:@{@"attribute1": @"a nice attribute"}];
                NSArray *eventQueueFake = [[NSArray alloc] initWithObjects:event, nil];
                eventsManager.eventQueue = [eventQueueFake mutableCopy];
                [eventsManager flush];
                
                MMEAPIClientFake *fakeAPIClient = [[MMEAPIClientFake alloc] init];
                spy_on(fakeAPIClient);
                fakeAPIClient.accessToken = @"access-token";
                fakeAPIClient.userAgentBase = @"user-agent-base";
                fakeAPIClient.hostSDKVersion = @"host-sdk-version";
                eventsManager.apiClient = fakeAPIClient;
                
                spy_on([MMEMetricsManager sharedManager].metrics);
            });
            
            afterEach(^{
                stop_spying_on([MMEMetricsManager sharedManager].metrics);
            });
            
            context(@"when the current time is before the next telemetryMetrics send date", ^{
                beforeEach(^{
                    [MMEMetricsManager sharedManager].metrics stub_method(@selector(recordingStarted)).and_return(NSDate.distantFuture);
                    
                    [eventsManager sendTelemetryMetricsEvent];
                });
                
                it(@"tells its api client to not post events", ^{
                    eventsManager.apiClient should_not have_received(@selector(postEvent:completionHandler:));
                });
            });
            
            context(@"when the current time is after the next telemetryMetrics send date", ^{
                beforeEach(^{
                    [MMEMetricsManager sharedManager].metrics stub_method(@selector(recordingStarted)).and_return(NSDate.distantPast);
                    [eventsManager sendTelemetryMetricsEvent];
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
            NSDateFormatter *dateFormatter = MMEDate.iso8601DateFormatter;
            spy_on(dateFormatter);
            dateFormatter stub_method(@selector(stringFromDate:)).and_return(dateString);
            commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"a nice vendor id";
            commonEventData.model = @"a nice model";
            commonEventData.osVersion = @"a nice ios version";
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
                    expectedEvent.dateStorage = event.dateStorage;

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
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a map download start event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEventTypeOfflineDownloadStart attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapOfflineDownloadStartEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a map download end event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:MMEventTypeOfflineDownloadEnd attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent mapOfflineDownloadEndEventWithDateString:dateString attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = [MMEDate dateWithDate:event.date];

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
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a vision event is pushed", ^{
                __block NSString * visionEventName = @"vision.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:visionEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent visionEventWithName:visionEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a search event is pushed", ^{
                __block NSString * searchEventName = @"search.*";
                
                beforeEach(^{
                    [eventsManager enqueueEventWithName:searchEventName attributes:attributes];
                });
                
                it(@"has the correct event", ^{
                    MMEEvent *expectedEvent = [MMEEvent searchEventWithName:searchEventName attributes:attributes];
                    MMEEvent *event = eventsManager.eventQueue.firstObject;
                    expectedEvent.dateStorage = event.dateStorage;

                    event should equal(expectedEvent);
                });
            });
            
            context(@"when a generic event is pushed", ^{
                beforeEach(^{
                    [eventsManager enqueueEventWithName:@"generic" attributes:attributes];
                });
                
                it(@"does queue the event", ^{
                    eventsManager.eventQueue.count should equal(1);
                });
            });
        });
    });
    
    describe(@"- enqueueEventWithName:", ^{
        __block NSString *dateString;
        __block MMECommonEventData *commonEventData;
        
        beforeEach(^{
            dateString = @"A nice date";
            NSDateFormatter *dateFormatter = MMEDate.iso8601DateFormatter;
            spy_on(dateFormatter);
            dateFormatter stub_method(@selector(stringFromDate:)).and_return(dateString);
            commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"a nice vendor id";
            commonEventData.model = @"a nice model";
            commonEventData.osVersion = @"a nice ios version";
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
                    expectedEvent.dateStorage = event.dateStorage;

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
                
                it(@"should queue events", ^{
                    eventsManager.eventQueue.count should equal(1);
                });
            });
        });
    });

    describe(@"- pushEvent:", ^{
        beforeEach(^{
            eventsManager.paused = YES;
        });

        context(@"when an error event is pushed", ^{
            NSError* testError = [NSError.alloc initWithDomain:NSCocoaErrorDomain code:999 userInfo:@{
                NSLocalizedDescriptionKey: @"Test Error Description",
                NSLocalizedFailureReasonErrorKey: @"Test Error Failure Reason"
            }];

            it(@"should not queue error events", ^{
                [MMEEventsManager.sharedManager pushEvent:[MMEEvent debugEventWithError:testError]];
                eventsManager.eventQueue.count should equal(0);
            });
        });

        context(@"when an exception event is pushed", ^{
            NSException* testException = [NSException.alloc initWithName:@"TestExceptionName" reason:@"TestExceptionReason" userInfo:nil];

            it(@"should not queue exception events", ^{
                [MMEEventsManager.sharedManager pushEvent:[MMEEvent debugEventWithException:testException]];
                eventsManager.eventQueue.count should equal(0);
            });
        });
    });

    describe(@"MMELocationManagerDelegate", ^{
        
        context(@"-[MMEEventsManager locatizonManager:didVisit:]", ^{
            __block CLVisit *visit;
            
            beforeEach(^{
                eventsManager.delegate = nice_fake_for(@protocol(MMEEventsManagerDelegate));
                eventsManager.paused = NO;
                
                visit = [[CLVisit alloc] init];
                spy_on(visit);
                
                CLLocationCoordinate2D coordinate = {10.0, -10.0};
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
                
                visit stub_method(@selector(coordinate)).and_return(coordinate);
                visit stub_method(@selector(arrivalDate)).and_return(date);
                visit stub_method(@selector(departureDate)).and_return(date);
                visit stub_method(@selector(horizontalAccuracy)).and_return(42.0);
                
                [eventsManager locationManager:eventsManager.locationManager didVisit:visit];
            });
            
            it(@"enqueues the correct event", ^{
                CLLocation *location = [[CLLocation alloc] initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude];
                NSDictionary *attributes = @{
                    MMEEventKeyCreated: [MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]],
                    MMEEventKeyLatitude: @([location mme_latitudeRoundedWithPrecision:7]),
                    MMEEventKeyLongitude: @([location mme_longitudeRoundedWithPrecision:7]),
                    MMEEventHorizontalAccuracy: @(visit.horizontalAccuracy),
                    MMEEventKeyArrivalDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.arrivalDate],
                    MMEEventKeyDepartureDate: [MMEDate.iso8601DateFormatter stringFromDate:visit.departureDate]
                };
                MMEEvent *expectedVisitEvent = [MMEEvent visitEventWithAttributes:attributes];
                MMEEvent *enqueueEvent = eventsManager.eventQueue.firstObject;

                expectedVisitEvent.dateStorage = enqueueEvent.dateStorage;

                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                [tempDict addEntriesFromDictionary:enqueueEvent.attributes];
                [tempDict setObject:[MMEDate.iso8601DateFormatter stringFromDate:[location timestamp]] forKey:@"created"];
                enqueueEvent.attributesStorage = tempDict;
                
                enqueueEvent should equal(expectedVisitEvent);
            });
            
            it(@"tells its delegate", ^{
                eventsManager.delegate should have_received(@selector(eventsManager:didVisit:)).with(eventsManager, visit);
            });
        });
    });
});

SPEC_END
