#import <XCTest/XCTest.h>

#import "MMEAPIClient.h"
#import "MMENSURLSessionWrapper.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMEConstants.h"

#import "NSUserDefaults+MMEConfiguration.h"
#import "NSUserDefaults+MMEConfiguration_Private.h"
#import "NSData+MMEGZIP.h"

@interface MMENSURLSessionWrapper (Private)
@property (nonatomic) NSURLSession *session;
@end

@interface MMEAPIClientTests : XCTestCase

@property (nonatomic) MMEAPIClient *apiClient;
@property (nonatomic) NSURLSessionAuthChallengeDisposition receivedDisposition;
@property (nonatomic) MMENSURLSessionWrapper *sessionWrapper;
@property (nonatomic) MMENSURLSessionWrapperFake *sessionWrapperFake;
@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSURLSession *capturedSession;
@property (nonatomic) NSURLAuthenticationChallenge *challenge;

@end

@interface MMEAPIClient (Tests)
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@end

@implementation MMEAPIClientTests

- (void)setUp {
    self.apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                            userAgentBase:@"user-agent-base"
                                           hostSDKVersion:@"host-sdk-1"];
    
    self.sessionWrapper = (MMENSURLSessionWrapper *)self.apiClient.sessionWrapper;
    self.sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self.sessionWrapper delegateQueue:nil];
}

- (void)tearDown {
    [NSUserDefaults mme_resetConfiguration];
}

- (void)testInitialization {
    XCTAssertNotNil(self.apiClient.sessionWrapper);
}

- (void)testPostingAnEvent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the completion handler"];

    MMENSURLSessionWrapperFake *sessionWrapperFake = [self setUpAPIClientToTestPosting];

    MMEEvent *event = [self locationEvent];
    [self.apiClient postEvent:event completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    // It should tell its session wrapper to process a request with a completion handler
    XCTAssertTrue([sessionWrapperFake received:@selector(processRequest:completionHandler:)]);

    // The request should be created correctly
    NSString *expectedURLString = [NSString stringWithFormat:@"%@/%@?access_token=%@", MMEAPIClientBaseURL, MMEAPIClientEventsPath, NSUserDefaults.mme_configuration.mme_accessToken];
    XCTAssertEqualObjects(sessionWrapperFake.request.URL.absoluteString, expectedURLString);
    XCTAssertEqualObjects(sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldUserAgentKey], NSUserDefaults.mme_configuration.mme_userAgentString);
    XCTAssertEqualObjects(sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentTypeKey], MMEAPIClientHeaderFieldContentTypeValue);
    XCTAssertEqualObjects(sessionWrapperFake.request.HTTPMethod, MMEAPIClientHTTPMethodPost);
    XCTAssertNil(sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey]);
    XCTAssertEqualObjects(sessionWrapperFake.request.HTTPBody, [self jsonDataForEvents:@[event]]);

    // When the session wrapper returns with a status code < 400
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [sessionWrapperFake completeProcessingWithData:nil response:response error:nil];

    // It should complete the post event with no error
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testPostingTwoEvents {
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the completion handler"];
    
    MMENSURLSessionWrapperFake *sessionWrapperFake = [self setUpAPIClientToTestPosting];
    
    MMEEvent *eventOne = [self locationEvent];
    MMEEvent *eventTwo = [self locationEvent];
    
    [self.apiClient postEvents:@[eventOne, eventTwo] completionHandler:^(NSError * _Nullable error) {
        [expectation fulfill];
    }];
    
    // It should tell its session wrapper to process a request with a completion handler
    XCTAssertTrue([sessionWrapperFake received:@selector(processRequest:completionHandler:)]);
    XCTAssertEqualObjects(sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey], @"gzip");
    
    // When the session wrapper returns with a status code < 400
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [sessionWrapperFake completeProcessingWithData:nil response:response error:nil];
    
    // It should complete the post event with no error
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testPostingAnEventWithAnHTTPStatusErrorResponse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the completion handler"];
    
    MMENSURLSessionWrapperFake *sessionWrapperFake = [self setUpAPIClientToTestPosting];
    
    MMEEvent *event = [self locationEvent];
    [self.apiClient postEvent:event completionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    
    // When the session wrapper returns with a status code < 400 and an error
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                              statusCode:400
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [sessionWrapperFake completeProcessingWithData:nil response:response error:nil];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testPostingAnEventWithALibraryErrorResponse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the completion handler"];
    
    MMENSURLSessionWrapperFake *sessionWrapperFake = [self setUpAPIClientToTestPosting];
    
    MMEEvent *event = [self locationEvent];
    NSError *postError = [NSError errorWithDomain:@"error.com" code:42 userInfo:nil];
    [self.apiClient postEvent:event completionHandler:^(NSError * _Nullable error) {
        XCTAssertEqualObjects(postError, error);
        [expectation fulfill];
    }];
    
    // When the session wrapper returns with a status code < 400 and an error
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http:test.com"]
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [sessionWrapperFake completeProcessingWithData:nil response:response error:postError];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testPostingAnEventWithAStagingAccessToken {
    NSString *stagingAccessToken = @"staging-access-token";
    [NSUserDefaults.mme_configuration mme_setAccessToken:stagingAccessToken];
    
    MMENSURLSessionWrapperFake *sessionWrapperFake = [self setUpAPIClientToTestPosting];
    [self.apiClient postEvent:[self locationEvent] completionHandler:nil];
    
    // It should tell its session wrapper to process a request with a completion handler
    XCTAssertTrue([sessionWrapperFake received:@selector(processRequest:completionHandler:)]);
    
    // The request should be created correctly
    NSString *expectedURLString = [NSString stringWithFormat:@"%@/%@?access_token=%@", MMEAPIClientBaseURL, MMEAPIClientEventsPath, stagingAccessToken];
    XCTAssertEqualObjects(sessionWrapperFake.request.URL.absoluteString, expectedURLString);
}

- (void)testSettingUpUserAgent {
    NSBundle *fakeApplicationBundle = [NSBundle bundleForClass:[MMEAPIClientTests class]];
    self.apiClient.applicationBundle = fakeApplicationBundle;
    [self.apiClient setupUserAgent];

    NSString *appName = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersion = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildNumber = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];

    NSString *expectedUserAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, self.apiClient.userAgentBase, self.apiClient.hostSDKVersion];
    XCTAssertEqualObjects(expectedUserAgent, self.apiClient.userAgent);
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

- (void)testPostMetadata {
    self.apiClient.sessionWrapper = self.sessionWrapperFake;
    NSArray *parameters = @[@{@"name": @"file", @"fileName": @"images.jpeg"},
                            @{@"name": @"attachments", @"value": @"[{\"name\":\"images.jpeg\",\"format\":\"jpg\",\"eventId\":\"123\",\"created\":\"2018-08-28T16:36:39+00:00\",\"size\":66962,\"type\":\"image\",\"startTime\":\"2018-08-28T16:36:39+00:00\",\"endTime\":\"2018-08-28T16:36:40+00:00\"}]"}];
    
    [self.apiClient postMetadata:parameters filePaths:@[@"../filepath"] completionHandler:^(NSError * _Nullable error) {
        // empty
    }];
    
    XCTAssert([(MMETestStub*)self.apiClient.sessionWrapper received:@selector(processRequest:completionHandler:)]);
}

- (void)testPostEventsCompression {
    self.apiClient.sessionWrapper = self.sessionWrapperFake;
    
    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
    commonEventData.vendorId = @"vendor-id";
    commonEventData.model = @"model";
    commonEventData.osVersion = @"1";
    commonEventData.scale = 42;
    
    MMEEvent *event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
    MMEEvent *eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
    
    NSArray *events = @[event, eventTwo];
    
    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];
    
    NSData *uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];
    
    [self.apiClient postEvents:@[event, eventTwo] completionHandler:nil];
    
    XCTAssert([self.sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey] isEqualToString:@"gzip"]);
    
    NSData *data = (NSData *)self.sessionWrapperFake.request.HTTPBody; //compressed data
    XCTAssert(data.length < uncompressedData.length);
    
    XCTAssert(data.mme_gunzippedData.length == uncompressedData.length);
}

#pragma mark - Utilities

- (NSData *)jsonDataForEvents:(NSArray *)events {
    NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
    [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        if (event.attributes) {
            [eventAttributes addObject:event.attributes];
        }
    }];
    return [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];
}

- (MMEEvent *)locationEvent {
    MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
    commonEventData.vendorId = @"vendor-id";
    commonEventData.model = @"model";
    commonEventData.iOSVersion = @"1";
    commonEventData.scale = 42;
    return [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
}

- (MMENSURLSessionWrapperFake *)setUpAPIClientToTestPosting {
    MMENSURLSessionWrapperFake *sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
    self.apiClient.sessionWrapper = sessionWrapperFake;
    self.apiClient.accessToken = @"an-access-token";
    return sessionWrapperFake;
}

@end
