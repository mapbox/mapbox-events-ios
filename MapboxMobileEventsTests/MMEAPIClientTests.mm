#import <Cedar/Cedar.h>
#import <Foundation/Foundation.h>
#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEAPIClientFake.h"
#import "MMECertPin.h"

@interface MMENSURLSessionWrapper (Private)
@property (nonatomic) NSURLSession *session;
@end

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface DelegateTestClass : NSObject<NSURLConnectionDelegate, NSURLAuthenticationChallengeSender>
@end

@interface MMEAPIClient (Tests)

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic) BOOL usesTestServer;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic, copy) NSString *userAgent;

- (void)setupUserAgent;

@end

@interface MMENSURLSessionWrapper (MMEAPIClientTests)

@property (nonatomic) MMECertPin *certPin;

@end

SPEC_BEGIN(MMEAPIClientSpec)

describe(@"MMEAPIClient", ^{
    
    __block MMEAPIClient *apiClient;
    __block NSURLSessionAuthChallengeDisposition receivedDisposition;
    __block MMENSURLSessionWrapper *sessionWrapper;
    __block NSURLSession *urlSession;
    __block NSURLAuthenticationChallenge *challenge;
    id<CedarDouble> delegateFake = fake_for(@protocol(NSURLAuthenticationChallengeSender));
    
    int64_t timeoutInNanoseconds = 1000000000;
    
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
    
    it(@"uses the default base URL value", ^{
        apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
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
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeoutInNanoseconds), dispatch_get_main_queue(), ^{
                    dispatch_semaphore_signal(semaphore);
                });
                
                [sessionWrapper URLSession:urlSession didReceiveChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
                    isMainThread = [NSThread isMainThread];
                    receivedDisposition = disposition;
                    dispatch_semaphore_signal(semaphore);
                }];
                
                while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
                }
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
                
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeoutInNanoseconds), dispatch_get_main_queue(), ^{
                    dispatch_semaphore_signal(semaphore);
                });
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [sessionWrapper URLSession:urlSession didReceiveChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
                        isMainThread = [NSThread isMainThread];
                        receivedDisposition = disposition;
                        dispatch_semaphore_signal(semaphore);
                    }];
                });
                
                while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
                }

            });
            
            it(@"should be main thread", ^{
                isMainThread should be_truthy;
            });
            
            it(@"should equal expected DefaultHandling disposition", ^{
                receivedDisposition should equal(NSURLSessionAuthChallengeCancelAuthenticationChallenge);
            });
        });
    });
    
    describe(@"- setBaseURL", ^{
        
        context(@"when the URL string is secure", ^{
            __block NSString *testURLString = @"https://test.com";
            
            beforeEach(^{
                apiClient.baseURL = [NSURL URLWithString:testURLString];
            });
            
            it(@"uses the passed in value", ^{
                apiClient.baseURL should equal([NSURL URLWithString:testURLString]);
            });
            
            context(@"when the URL is reset with a nil value", ^{
                beforeEach(^{
                    apiClient.baseURL = nil;
                });
                
                it(@"use the default base URL value", ^{
                    apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
                });
            });
        });
        
        context(@"when the URL is not secure", ^{
            __block NSString *badTestURLString = @"http://test.com";
            
            beforeEach(^{
                apiClient.baseURL = [NSURL URLWithString:badTestURLString];
            });
            
            it(@"ignores the insecure URL and uses the default base URL value", ^{
                apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            });
        });
        
        context(@"when plist configured API endpoint to China API", ^{
            beforeEach(^{
                spy_on([NSBundle mainBundle]);
                [NSBundle mainBundle] stub_method(@selector(objectForInfoDictionaryKey:)).with(@"MGLMapboxAPIBaseURL").and_return(MMEAPIClientBaseChinaAPIURL);
                apiClient.baseURL = nil;
            });

            it(@"auto switch the events endpoint to China events API", ^{
                apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseChinaEventsURL]);
            });
        });

        context(@"when setting up user agent", ^{
            __block NSString *expectedUserAgent;

            beforeEach(^{
                apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                        userAgentBase:@"user-agent-base"
                                                       hostSDKVersion:@"host-sdk-1"];
                
                NSBundle *fakeApplicationBundle = [NSBundle bundleForClass:[MMEAPIClientSpec class]];
                apiClient.applicationBundle = fakeApplicationBundle;
                [apiClient setupUserAgent];

                NSString *appName = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
                NSString *appVersion = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                NSString *appBuildNumber = [fakeApplicationBundle objectForInfoDictionaryKey:@"CFBundleVersion"];

                expectedUserAgent = [NSString stringWithFormat:@"%@/%@/%@ %@/%@", appName, appVersion, appBuildNumber, apiClient.userAgentBase, apiClient.hostSDKVersion];                
            });

            it(@"should equal expectedUserAgent", ^{
                expectedUserAgent should equal(apiClient.userAgent);
            });
        });
    });
    
    describe(@"- getConfigurationWithCompletionHandler:", ^{
        __block MMENSURLSessionWrapperFake *sessionWrapperFake;
        __block NSError *capturedError;
        
        beforeEach(^{
            sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
            spy_on(sessionWrapperFake);
            
            apiClient.sessionWrapper = sessionWrapperFake;
        });
        
        context(@"when getting configuration", ^{
            __block NSError *error;
            
            beforeEach(^{
                [apiClient getConfigurationWithCompletionHandler:^(NSError * _Nullable error, NSData * _Nullable data) {
                    capturedError = error;
                }];
            });
            
            context(@"when network is offline", ^{
                beforeEach(^{
                    error = [NSError errorWithDomain:@"test" code:42 userInfo:nil];
                    NSHTTPURLResponse *responseFake = nil;
                    NSURLRequest *requestFake = [[NSURLRequest alloc] initWithURL:apiClient.baseURL];
                    
                    [sessionWrapperFake completeProcessingWithData:nil response:responseFake error:error];
                    [apiClient statusErrorFromRequest:requestFake andHTTPResponse:responseFake] should be_nil;
                    [apiClient unexpectedResponseErrorfromRequest:requestFake andResponse:responseFake] should_not be_nil;
                });
                
                it(@"should equal completed process error", ^{
                    capturedError should equal(error);
                });
            });
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
                    NSHTTPURLResponse *responseFake = [[NSHTTPURLResponse alloc] initWithURL:apiClient.baseURL statusCode:400 HTTPVersion:nil headerFields:nil];
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
                apiClient.accessToken = stagingAccessToken;
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
