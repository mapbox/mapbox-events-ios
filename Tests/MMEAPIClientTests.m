#import <XCTest/XCTest.h>

#import "MMEAPIClient.h"
#import "MMENSURLSessionWrapper.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEEvent.h"
#import "MMEConstants.h"
#import "MMEMetricsManager.h"
#import "MMELogger.h"
#import "NSData+MMEGZIP.h"
#import "MMEMockEventConfig.h"
#import "MMEAPIClientBlockCounter.h"
#import "MMEAPIClient+Mock.h"
#import "EventConfigStubProtocol.h"
#import "EventStubProtocol.h"
#import "ErrorStubProtocol.h"
#import "MMEConfig.h"
#import "MMENSURLRequestFactory.h"
#import "MMEAPIClient+Mock.h"

@interface MMENSURLSessionWrapper (Private)
@property (nonatomic) NSURLSession *session;
@end

// MARK: -

@interface MMEAPIClientTests : XCTestCase

@property (nonatomic) MMEAPIClient *apiClient;
@property (nonatomic) NSURLSessionAuthChallengeDisposition receivedDisposition;
@property (nonatomic) MMENSURLSessionWrapper *sessionWrapper;
@property (nonatomic) MMENSURLSessionWrapperFake *sessionWrapperFake;
@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSURLSession *capturedSession;
@property (nonatomic) NSURLAuthenticationChallenge *challenge;
@property (nonatomic) MMEAPIClientBlockCounter* blockCounter;

@end

// MARK: -

@interface MMEAPIClient (Tests)
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@end

// MARK: -

@interface DelegateTestClass : NSObject<NSURLConnectionDelegate, NSURLAuthenticationChallengeSender>
@end

// MARK: -

@implementation MMEAPIClientTests

- (void)setUp {

    MMEMockEventConfig *eventConfig = [[MMEMockEventConfig alloc] init];
    self.blockCounter = [[MMEAPIClientBlockCounter alloc] init];

    __weak __typeof__(self) weakSelf = self;

    // Configure Client with Block Counter to inspect interal Call behaviors
    self.apiClient = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                     onSerializationError:^(NSError * _Nonnull error) {
        [[[weakSelf blockCounter] onSerializationErrors] addObject:error];
    } onURLResponse:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[[weakSelf blockCounter] onURLResponses] addObject:request];
    } onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {
        [[[weakSelf blockCounter] eventQueue] addObject:eventQueue];
    } onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {
        [[[weakSelf blockCounter] eventCount] addObject:[NSNumber numberWithUnsignedInteger:eventCount]];
    } onGenerateTelemetryEvent:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.blockCounter.generateTelemetry += 1;
        }
    }];

    self.sessionWrapper = (MMENSURLSessionWrapper *)self.apiClient.sessionWrapper;
    self.sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self.sessionWrapper delegateQueue:nil];
}

- (void)tearDown {

}

- (void)testSessionWrapperInvalidates {
    self.capturedSession = self.sessionWrapper.session;
    [self.sessionWrapper invalidate];
    
    // wait a second for the session to invalidate
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    
    XCTAssertNil(self.capturedSession.delegate);
}

- (void)testPinningValidatorIsOnMainThreadAndCancelsChallenge {
    __block bool isMainThread;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should get called after pinning validation receives a challenge"];
    
    [self.sessionWrapper URLSession:self.urlSession didReceiveChallenge:self.challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
        isMainThread = [NSThread isMainThread];
        self.receivedDisposition = disposition;
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5];
    
    XCTAssert(isMainThread = YES);
    XCTAssert(self.receivedDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge);
}

- (void)testPinningValidatorIsOnMainThreadAndCancelsChallengeStartedOnBackgroundThread {
    __block bool isMainThread;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should get called after pinning validation receives a challenge"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.sessionWrapper URLSession:self.urlSession didReceiveChallenge:self.challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
            isMainThread = [NSThread isMainThread];
            self.receivedDisposition = disposition;
            
            [expectation fulfill];
        }];
    });
        
    [self waitForExpectations:@[expectation] timeout:5];
    
    XCTAssert(isMainThread = YES);
    XCTAssert(self.receivedDisposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge);
}


// MARK: - Round Trip Request -> Responses

- (void)testGetConfigResponse {

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[EventConfigStubProtocol.self];
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:[[MMEMockEventConfig alloc] init]];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;

    // Configure Client with Block Counter to inspect interal Call behaviors
    __weak __typeof__(self) weakSelf = self;
    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                           requestFactory: [[MMENSURLRequestFactory alloc] initWithConfig:eventConfig]
                                                  session:session
                                     onSerializationError:^(NSError * _Nonnull error) {

        [[[weakSelf blockCounter] onSerializationErrors] addObject:error];
    } onURLResponse:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[[weakSelf blockCounter] onURLResponses] addObject:request];
    } onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {
        [[[weakSelf blockCounter] eventQueue] addObject:eventQueue];
    } onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {
        [[[weakSelf blockCounter] eventCount] addObject:[NSNumber numberWithUnsignedInteger:eventCount]];
    } onGenerateTelemetryEvent:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.blockCounter.generateTelemetry += 1;
        }
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch Event Config"];

    [client getEventConfigWithCompletionHandler:^(
                                                 MMEConfig * _Nullable config,
                                                 NSError * _Nullable error) {
        XCTAssertNotNil(config);

        XCTAssertEqualObjects(config.certificateRevocationList, nil);
        XCTAssertEqualObjects(config.telemetryTypeOverride, @2.0);
        XCTAssertEqualObjects(config.geofenceOverride, @444.0);
        XCTAssertEqualObjects(config.backgroundStartupOverride, @44.0);
        XCTAssertEqualObjects(config.eventTag, @"all");

        // Inspect Block Calls Validating Block Callback Behavior
        XCTAssertEqual(weakSelf.blockCounter.onURLResponses.count, 1);
        XCTAssertEqual(weakSelf.blockCounter.onSerializationErrors.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.eventQueue.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.eventCount.count, 1);
        XCTAssertEqual(weakSelf.blockCounter.generateTelemetry, 1);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:3];
}

- (void)testPostEvent {
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[EventStubProtocol.self];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:eventConfig]; 

    // Configure Client with Block Counter to inspect interal Call behaviors
    __weak __typeof__(self) weakSelf = self;
    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                                 requestFactory: [[MMENSURLRequestFactory alloc] initWithConfig:eventConfig]
                                                        session:session
                                           onSerializationError:^(NSError * _Nonnull error) {

        [[[weakSelf blockCounter] onSerializationErrors] addObject:error];
    } onURLResponse:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[[weakSelf blockCounter] onURLResponses] addObject:request];
    } onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {
        [[[weakSelf blockCounter] eventQueue] addObject:eventQueue];
    } onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {
        [[[weakSelf blockCounter] eventCount] addObject:[NSNumber numberWithUnsignedInteger:eventCount]];
    } onGenerateTelemetryEvent:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.blockCounter.generateTelemetry += 1;
        }
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Post Event"];
    MMEEvent* event = [MMEEvent turnstileEventWithAttributes:@{}];

    [client postEvent:event completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);

        // Inspect Block Calls Validating Block Callback Behavior
        XCTAssertEqual(weakSelf.blockCounter.onURLResponses.count, 1);
        XCTAssertEqual(weakSelf.blockCounter.onSerializationErrors.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.eventQueue.count, 1);
        XCTAssertEqual(weakSelf.blockCounter.eventCount.count, 2);
        XCTAssertEqual(weakSelf.blockCounter.generateTelemetry, 1);

        [expectation fulfill];
    }];

    XCTAssertEqual(self.blockCounter.onURLResponses.count, 0);
    XCTAssertEqual(self.blockCounter.onSerializationErrors.count, 0);
    XCTAssertEqual(self.blockCounter.eventQueue.count, 1);
    XCTAssertEqual(self.blockCounter.eventCount.count, 1);
    XCTAssertEqual(self.blockCounter.generateTelemetry, 1);

    [self waitForExpectations:@[expectation] timeout:2];
}

-(void)testErrorResponse {
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[ErrorStubProtocol.self];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:eventConfig];

    // Configure Client with Block Counter to inspect interal Call behaviors
    __weak __typeof__(self) weakSelf = self;
    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                                 requestFactory: [[MMENSURLRequestFactory alloc] initWithConfig:eventConfig]
                                                        session:session
                                           onSerializationError:^(NSError * _Nonnull error) {

        [[[weakSelf blockCounter] onSerializationErrors] addObject:error];
    } onURLResponse:^(NSData * _Nullable data, NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[[weakSelf blockCounter] onURLResponses] addObject:request];
    } onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {
        [[[weakSelf blockCounter] eventQueue] addObject:eventQueue];
    } onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {
        [[[weakSelf blockCounter] eventCount] addObject:[NSNumber numberWithUnsignedInteger:eventCount]];
    } onGenerateTelemetryEvent:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.blockCounter.generateTelemetry += 1;
        }
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Error Response"];

    [client getEventConfigWithCompletionHandler:^(MMEConfig * _Nullable config, NSError * _Nullable error) {

        XCTAssertNotNil(error);

        // Inspect Block Calls Validating Block Callback Behavior
        XCTAssertEqual(weakSelf.blockCounter.onURLResponses.count, 1);
        XCTAssertEqual(weakSelf.blockCounter.onSerializationErrors.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.eventQueue.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.eventCount.count, 0);
        XCTAssertEqual(weakSelf.blockCounter.generateTelemetry, 0);

        [expectation fulfill];
    }];

    XCTAssertEqual(self.blockCounter.onURLResponses.count, 0);
    XCTAssertEqual(self.blockCounter.onSerializationErrors.count, 0);
    XCTAssertEqual(self.blockCounter.eventQueue.count, 0);
    XCTAssertEqual(self.blockCounter.eventCount.count, 0);
    XCTAssertEqual(self.blockCounter.generateTelemetry, 0);

    [self waitForExpectations:@[expectation] timeout:20];
}


- (void)testPostMetadata {
    self.apiClient.sessionWrapper = self.sessionWrapperFake;
    NSArray *parameters = @[
        @{@"name": @"file",
          @"fileName": @"images.jpeg"},
        @{@"name": @"attachments",
          @"value": @"[{\"name\":\"images.jpeg\",\"format\":\"jpg\",\"eventId\":\"123\",\"created\":\"2018-08-28T16:36:39+00:00\",\"size\":66962,\"type\":\"image\",\"startTime\":\"2018-08-28T16:36:39+00:00\",\"endTime\":\"2018-08-28T16:36:40+00:00\"}]"}];
    
    [self.apiClient postMetadata:parameters filePaths:@[@"../filepath"] completionHandler:^(NSError * _Nullable error) {
        // empty
    }];
    
    XCTAssert([(MMETestStub*)self.apiClient.sessionWrapper received:@selector(processRequest:completionHandler:)]);
}

- (void)testPostEventsCompression {
    self.apiClient.sessionWrapper = self.sessionWrapperFake;
        
    MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
    MMEEvent *eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-2" commonEventData:nil];
    
    NSArray *events = @[event, eventTwo];
    
    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];
    
    NSData *uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];


    [self.apiClient postEvents:@[event, eventTwo] completionHandler:nil];
    XCTAssert([(MMETestStub*)self.apiClient.sessionWrapper received:@selector(processRequest:completionHandler:)]);

    XCTAssert([self.sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey] isEqualToString:@"gzip"]);
    
    NSData *data = (NSData *)self.sessionWrapperFake.request.HTTPBody; //compressed data
    XCTAssertLessThan(data.length, uncompressedData.length);
    XCTAssertEqual(data.mme_gunzippedData.length, uncompressedData.length);

    // Inspect Synchronous Block Calls Validating Block Callback Behavior
    XCTAssertEqual(self.blockCounter.onURLResponses.count, 0);
    XCTAssertEqual(self.blockCounter.onSerializationErrors.count, 0);
    XCTAssertEqual(self.blockCounter.eventQueue.count, 1);
    XCTAssertEqual(self.blockCounter.eventCount.count, 1);
    XCTAssertEqual(self.blockCounter.generateTelemetry, 1);
}

- (void) testMMEAPIClientSetup {
    // it has the correct type of session wrapper
    XCTAssertNotNil(self.apiClient.sessionWrapper);
    XCTAssert([self.apiClient.sessionWrapper isKindOfClass:MMENSURLSessionWrapper.class]);
}


@end
