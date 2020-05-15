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
#import "MMEConfig.h"

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
                                                  onError:^(NSError * _Nonnull error) {
        [[[weakSelf blockCounter] onErrors] addObject:error];
                                                }
                                          onBytesReceived:^(NSUInteger bytes) {
        [[[weakSelf blockCounter] onBytesReceived] addObject:[NSNumber numberWithUnsignedInteger:bytes]];
                                                }
                                       onEventQueueUpdate:^(NSArray * _Nonnull eventQueue) {

        [[[weakSelf blockCounter] eventQueue] addObject:eventQueue];
                                                }
                                       onEventCountUpdate:^(NSUInteger eventCount, NSURLRequest * _Nullable request, NSError * _Nullable error) {
                                                    // TBD Call Verification
        [[[weakSelf blockCounter] eventCount] addObject:[NSNumber numberWithUnsignedInteger:eventCount]];
                                                }
                                 onGenerateTelemetryEvent:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.blockCounter.generateTelemetry += 1;
        }
                                                }
                                               onLogEvent:^(MMEEvent * _Nonnull event) {
        [[[weakSelf blockCounter] logEvents] addObject:event];
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

- (void)testGetConfigURLRequest {
    MMEAPIClient* client = [MMEAPIClient clientWithMockConfig];
    NSURLRequest* request = client.eventConfigurationRequest;
    NSDictionary<NSString*, NSString*>* headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent":  @"<LegacyUserAgent>",
        @"X-Mapbox-Agent": @"<UserAgent>"
    };

    XCTAssertEqualObjects(@"https://config.mapbox.com/events-config?access_token=access-token", request.URL.absoluteString);
    XCTAssertEqualObjects(headers, request.allHTTPHeaderFields);
    XCTAssertNil(request.HTTPBody);
}

- (void)testGetConfigResponse {

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[EventConfigStubProtocol.self];
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:[[MMEMockEventConfig alloc] init]];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;

    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                                        session:session];
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
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:3];
}

- (void)testPostEventURLRequest {
    MMEAPIClient* client = [MMEAPIClient clientWithMockConfig];
    MMEEvent* event = [MMEEvent turnstileEventWithAttributes:@{}];
    NSURLRequest* request = [client requestForEvents:@[event]];
    NSDictionary<NSString*, NSString*>* headers = @{
        @"Content-Type": @"application/json",
        @"User-Agent":  @"<LegacyUserAgent>",
        @"X-Mapbox-Agent": @"<UserAgent>"
    };

    XCTAssertEqualObjects(@"https://events.mapbox.com/events/v2?access_token=access-token", request.URL.absoluteString);
    XCTAssertEqualObjects(headers, request.allHTTPHeaderFields);
    XCTAssertNotNil(request.HTTPBody);
}

- (void)testPostEvent {
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.protocolClasses = @[EventStubProtocol.self];
    MMEMockEventConfig* eventConfig = MMEMockEventConfig.oneSecondConfigUpdate;
    MMENSURLSessionWrapper* session = [[MMENSURLSessionWrapper alloc] initWithSessionConfiguration:sessionConfiguration
                                                                                eventConfiguration:eventConfig]; 

    MMEAPIClient* client = [[MMEAPIClient alloc] initWithConfig:eventConfig
                                                    session:session];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Post Event"];
    MMEEvent* event = [MMEEvent turnstileEventWithAttributes:@{}];
    [client postEvent:event completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:2];
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
    MMEEvent *eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
    
    NSArray *events = @[event, eventTwo];
    
    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];
    
    NSData *uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];

    // NSURLTask
    [self.apiClient postEvents:@[event, eventTwo] completionHandler:nil];
    
    XCTAssert([self.sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey] isEqualToString:@"gzip"]);
    
    NSData *data = (NSData *)self.sessionWrapperFake.request.HTTPBody; //compressed data
    XCTAssert(data.length < uncompressedData.length);
    
    XCTAssert(data.mme_gunzippedData.length == uncompressedData.length);

    // Inspect Block Calls Validating Block Callback Behavior
    XCTAssertEqual(self.blockCounter.onBytesReceived.count, 0);
    XCTAssertEqual(self.blockCounter.eventQueue.count, 1);
    XCTAssertEqual(self.blockCounter.eventCount.count, 1);
    XCTAssertEqual(self.blockCounter.generateTelemetry, 1);
    XCTAssertEqual(self.blockCounter.logEvents.count, 0);
}

- (void) testMMEAPIClientSetup {
    // it has the correct type of session wrapper
    XCTAssertNotNil(self.apiClient.sessionWrapper);
    XCTAssert([self.apiClient.sessionWrapper isKindOfClass:MMENSURLSessionWrapper.class]);
}

- (void) testPostSingleEvent {
    MMENSURLSessionWrapperFake *wrapper = [[MMENSURLSessionWrapperFake alloc] init];
    self.apiClient.sessionWrapper = wrapper;
    MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
}

// TODO: - Convert Cedar Tests

/*
describe(@"- postEvent:completionHandler:", ^{
    __block MMEEvent *event;
    __block MMENSURLSessionWrapperFake *sessionWrapperFake;
    __block NSError *capturedError;

beforeEach(^{
    sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
    spy_on(sessionWrapperFake);

    apiClient.sessionWrapper = sessionWrapperFake;
             
    event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:nil];
});
         
 context(@"when posting a single event", ^{
             
     beforeEach(^{
         [apiClient postEvent:event completionHandler:^(NSError * _Nullable error) {
             capturedError = error;
         }];
     });
     
     it(@"should have received processRequest:completionHandler:", ^{
         apiClient.sessionWrapper should have_received(@selector(processRequest:completionHandler:)).with(sessionWrapperFake.request).and_with(Arguments::anything);
     });
     
     context(@"when there is a network error", ^{
         __block NSError *error;
         
         beforeEach(^{
             error = [NSError errorWithDomain:@"test" code:42 userInfo:nil];
             NSHTTPURLResponse *responseFake = [[NSHTTPURLResponse alloc] initWithURL:NSUserDefaults.mme_configuration.mme_eventsServiceURL statusCode:400 HTTPVersion:nil headerFields:nil];
             [sessionWrapperFake completeProcessingWithData:nil response:responseFake error:error];
         });
         
         it(@"should equal completed process error", ^{
             capturedError should equal(error);
         });
     });
     
     context(@"when there is a response with an invalid status code", ^{
         beforeEach(^{
             NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                                      statusCode:400
                                                                     HTTPVersion:nil
                                                                    headerFields:nil];
             [sessionWrapperFake completeProcessingWithData:nil response:response error:nil];
         });
         
         it(@"should have an error", ^{
             capturedError should_not be_nil;
         });
     });
 });
 
 context(@"when posting a single event after an access token is set", ^{
     __block NSString *expectedURLString;
     
     beforeEach(^{
         NSString *stagingAccessToken = @"staging-access-token";
         NSUserDefaults.mme_configuration.mme_accessToken = stagingAccessToken;
         [apiClient postEvent:event completionHandler:nil];
         
         expectedURLString = [NSString stringWithFormat:@"%@/%@?access_token=%@", MMEAPIClientBaseURL, MMEAPIClientEventsPath, stagingAccessToken];
     });
     
     it(@"should receive processRequest:completionHandler", ^{
         sessionWrapperFake should have_received(@selector(processRequest:completionHandler:));
     });

     it(@"should be created properly", ^{
         sessionWrapperFake.request.URL.absoluteString should equal(expectedURLString);
     });

});*/

@end
