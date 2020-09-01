@import Cedar;
@import Foundation;

#import <MapboxMobileEvents/MMEAPIClient.h>
#import <MapboxMobileEvents/MMEConstants.h>
#import <MapboxMobileEvents/MMEEvent.h>
#import <MapboxMobileEvents/MMECommonEventData.h>
#import <MapboxMobileEvents/MMECertPin.h>
#import <MapboxMobileEvents/NSUserDefaults+MMEConfiguration.h>

#import "MMERunningLock.h"
#import "MMEAPIClientFake.h"
#import "MMENSURLSessionWrapperFake.h"

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
                    error = [NSError errorWithDomain:MMEErrorDomain code:0 userInfo:nil];
                    NSHTTPURLResponse *responseFake = [[NSHTTPURLResponse alloc] initWithURL:NSUserDefaults.mme_configuration.mme_eventsServiceURL statusCode:400 HTTPVersion:nil headerFields:nil];
                    [sessionWrapperFake completeProcessingWithData:nil response:responseFake error:error];
                });
                
                it(@"should equal completed process error", ^{
                    capturedError.code should equal(error.code);
                    capturedError.domain should equal(error.domain);
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
    });
});

SPEC_END
