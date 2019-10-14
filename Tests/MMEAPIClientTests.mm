@import Cedar;
@import Foundation;

#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEAPIClientFake.h"
#import "MMECertPin.h"
#import "MMERunningLock.h"

#import "NSUserDefaults+MMEConfiguration.h"

@interface MMENSURLSessionWrapper (Private)
@property (nonatomic) NSURLSession *session;
@end

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface DelegateTestClass : NSObject<NSURLConnectionDelegate, NSURLAuthenticationChallengeSender>
@end

// MARK: -

@interface MMEAPIClient (Tests)
@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;

@end

// MARK: -

@interface MMENSURLSessionWrapper (MMEAPIClientTests)
@property (nonatomic) MMECertPin *certPin;

@end

// MARK: -

SPEC_BEGIN(MMEAPIClientSpec)

describe(@"MMEAPIClient", ^{
    
    __block MMEAPIClient *apiClient;
    __block NSURLSessionAuthChallengeDisposition receivedDisposition;
    __block MMENSURLSessionWrapper *sessionWrapper;
    __block NSURLSession *urlSession;
    __block NSURLAuthenticationChallenge *challenge;
    id<CedarDouble> delegateFake = fake_for(@protocol(NSURLAuthenticationChallengeSender));
        
    beforeEach(^{
        apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                userAgentBase:@"user-agent-base"
                                               hostSDKVersion:@"host-sdk-1"];
        
        sessionWrapper = (MMENSURLSessionWrapper *)apiClient.sessionWrapper;
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:sessionWrapper delegateQueue:nil];
        
        NSURLProtectionSpace *space = [[NSURLProtectionSpace alloc] initWithHost:@"hostname" port:0 protocol:nil realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
        challenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:space proposedCredential:nil previousFailureCount:0 failureResponse:nil error:nil sender:((DelegateTestClass *)delegateFake)];
    });
    
    it(@"has the correct type of session wrapper", ^{
        apiClient.sessionWrapper should_not be_nil;
        apiClient.sessionWrapper should be_instance_of([MMENSURLSessionWrapper class]);
    });
        
    describe(@"- URLSession:didBecomeInvalidWithError:", ^{
        __block NSURLSession *capturedSession;
        
        context(@"when the session wrapper is invalidated", ^{
            capturedSession = sessionWrapper.session;
            [sessionWrapper invalidate];

            // wait a second for the session to invalidate
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

            it(@"should set original session delegate to nil", ^{
                capturedSession.delegate should be_nil;
            });
        });
    });
    
    describe(@"- URLSession:didReceiveChallenge:completionHandler:", ^{
        __block bool isMainThread;
        
        context(@"when the pinning validator does not handle the challenge", ^{
            beforeEach(^{
                MMERunningLock *lock = MMERunningLock.lockedRunningLock;
                [sessionWrapper URLSession:urlSession didReceiveChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
                    isMainThread = [NSThread isMainThread];
                    receivedDisposition = disposition;
                    [lock unlock];
                }];
                
                [lock runUntilTimeout:10] should be_truthy;
            });
            
            it(@"should be on main queue", ^{
                isMainThread should be_truthy;
            });
            
            it(@"should call the completion with the cancel disposition", ^{
                receivedDisposition should equal(NSURLSessionAuthChallengeCancelAuthenticationChallenge);
            });
        });
        
        context(@"when using a background thread", ^{
            __block bool isMainThread;
            
            beforeEach(^{
                
                MMERunningLock *lock = MMERunningLock.lockedRunningLock;

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [sessionWrapper URLSession:urlSession didReceiveChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
                        isMainThread = [NSThread isMainThread];
                        receivedDisposition = disposition;
                        [lock unlock];
                    }];
                });
                
                [lock runUntilTimeout:10] should be_truthy;
            });
            
            it(@"should be main thread", ^{
                isMainThread should be_truthy;
            });
            
            it(@"should equal expected DefaultHandling disposition", ^{
                receivedDisposition should equal(NSURLSessionAuthChallengeCancelAuthenticationChallenge);
            });
        });
    });
    
    describe(@"- getConfigurationWithCompletionHandler:", ^{
        __block MMENSURLSessionWrapperFake *sessionWrapperFake;
        
        beforeEach(^{
            sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
            spy_on(sessionWrapperFake);
            
            apiClient.sessionWrapper = sessionWrapperFake;
        });
    });
        
    describe(@"- postEvent:completionHandler:", ^{
        __block MMEEvent *event;
        __block MMENSURLSessionWrapperFake *sessionWrapperFake;
        __block NSError *capturedError;
        
        beforeEach(^{
            
            sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
            spy_on(sessionWrapperFake);
            
            apiClient.sessionWrapper = sessionWrapperFake;
            
            MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"vendor-id";
            commonEventData.model = @"model";
            commonEventData.osVersion = @"1";
            commonEventData.scale = 42;
            
            event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
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

        });
        
        context(@"when posting two events", ^{
            __block MMEEvent *eventTwo;
            __block NSData *uncompressedData;
            
            beforeEach(^{
                MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
                commonEventData.vendorId = @"vendor-id";
                commonEventData.model = @"model";
                commonEventData.osVersion = @"1";
                commonEventData.scale = 42;
                
                eventTwo = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
                
                NSArray *events = @[event, eventTwo];
                
                NSMutableArray *eventAttributes = [NSMutableArray arrayWithCapacity:events.count];
                [events enumerateObjectsUsingBlock:^(MMEEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (event.attributes) {
                        [eventAttributes addObject:event.attributes];
                    }
                }];
                
                uncompressedData = [NSJSONSerialization dataWithJSONObject:eventAttributes options:0 error:nil];
                
                [apiClient postEvents:@[event, eventTwo] completionHandler:nil];
            });
            
            it(@"should use gzip for content encoding", ^{
                sessionWrapperFake.request.allHTTPHeaderFields[MMEAPIClientHeaderFieldContentEncodingKey] should equal(@"gzip");
            });
            
            it(@"should compress the data", ^{
                NSData *data = (NSData *)sessionWrapperFake.request.HTTPBody;
                data.length should be_less_than(uncompressedData.length);
            });
        });
    });
});

SPEC_END
