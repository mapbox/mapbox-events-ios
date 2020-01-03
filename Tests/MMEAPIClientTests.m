#import <XCTest/XCTest.h>

#import "MMEAPIClient.h"
#import "MMENSURLSessionWrapper.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEEvent.h"
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
    
    [self.apiClient postEvents:@[event, eventTwo] completionHandler:nil];
    
    XCTAssert([self.sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey] isEqualToString:@"gzip"]);
    
    NSData *data = (NSData *)self.sessionWrapperFake.request.HTTPBody; //compressed data
    XCTAssert(data.length < uncompressedData.length);
    
    XCTAssert(data.mme_gunzippedData.length == uncompressedData.length);
}

@end
