#import <Cedar/Cedar.h>
#import <Foundation/Foundation.h>
#import "MMEAPIClient.h"
#import "MMEConstants.h"
#import "MMEEvent.h"
#import "MMECommonEventData.h"
#import "MMETrustKitWrapper.h"
#import "MMENSURLSessionWrapperFake.h"
#import "MMEAPIClientFake.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MMEAPIClient (Tests)

@property (nonatomic) id<MMENSURLSessionWrapper> sessionWrapper;
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic) BOOL usesTestServer;
@property (nonatomic) NSBundle *applicationBundle;
@property (nonatomic, copy) NSString *userAgent;

- (void)setupUserAgent;

@end

SPEC_BEGIN(MMEAPIClientSpec)

describe(@"MMEAPIClient", ^{
    
    __block MMEAPIClient *apiClient;
    
    beforeEach(^{
        apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                userAgentBase:@"user-agent-base"
                                               hostSDKVersion:@"host-sdk-1"];
    });
    
    describe(@"- creating an api client instance", ^{
        context(@"when MMETelemetryTestServerURL is nil", ^{
            
            beforeEach(^{
                spy_on([NSUserDefaults standardUserDefaults]);
                [NSUserDefaults standardUserDefaults] stub_method(@selector(objectForKey:)).with(MMETelemetryTestServerURL).and_return(nil);
                
                apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                        userAgentBase:@"user-agent-base"
                                                       hostSDKVersion:@"host-sdk-1"];
                
                apiClient.sessionWrapper should_not be_nil;
            });
            
            afterEach(^{
                stop_spying_on([NSUserDefaults standardUserDefaults]);
            });
            
            it(@"should be the correct instance type", ^{
                apiClient.sessionWrapper should be_instance_of([MMENSURLSessionWrapper class]);
            });
            
            it(@"should set its base URL equal to the the base URL constant value", ^{
                apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            });
        });
        
        context(@"when a good URL is added to MMETelemetryTestServerURL", ^{
            __block NSString *testURLString = @"https://test.com";
            
            beforeEach(^{
                spy_on([NSUserDefaults standardUserDefaults]);
                [NSUserDefaults standardUserDefaults] stub_method(@selector(objectForKey:)).with(MMETelemetryTestServerURL).and_return(testURLString);
                
                apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                        userAgentBase:@"user-agent-base"
                                                       hostSDKVersion:@"host-sdk-1"];
            });
            
            it(@"should use test server", ^{
                apiClient.sessionWrapper.usesTestServer should be_truthy;
            });
            
            it(@"should equal a URL made from the test URL string", ^{
                apiClient.baseURL should equal([NSURL URLWithString:testURLString]);
            });
            
            afterEach(^{
                stop_spying_on([NSUserDefaults standardUserDefaults]);
            });
        });
        
        context(@"when a non-secure URL is added to MMETelemetryTestServerURL", ^{
            beforeEach(^{
                NSString *badTestURLString = @"http://test.com";
                spy_on([NSUserDefaults standardUserDefaults]);
                [NSUserDefaults standardUserDefaults] stub_method(@selector(objectForKey:)).with(MMETelemetryTestServerURL).and_return(badTestURLString);
                
                apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                        userAgentBase:@"user-agent-base"
                                                       hostSDKVersion:@"host-sdk-1"];
            });
            
            it(@"should NOT use test server", ^{
                apiClient.sessionWrapper.usesTestServer should be_falsy;
            });
            
            it(@"should equal the BaseURL constant", ^{
                apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            });
            
            afterEach(^{
                stop_spying_on([NSUserDefaults standardUserDefaults]);
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
            commonEventData.iOSVersion = @"1";
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
                    [sessionWrapperFake completeProcessingWithData:nil response:nil error:error];
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
        
        context(@"when posting a single event with a staging access token", ^{
            __block NSString *expectedURLString;
            
            beforeEach(^{
                NSString *stagingAccessToken = @"staging-access-token";
                [[NSUserDefaults standardUserDefaults] setObject:stagingAccessToken forKey:MMETelemetryStagingAccessToken];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [apiClient postEvent:event completionHandler:nil];
                
                expectedURLString = [NSString stringWithFormat:@"%@/%@?access_token=%@", MMEAPIClientBaseURL, MMEAPIClientEventsPath, stagingAccessToken];
            });
            
            afterEach(^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:MMETelemetryStagingAccessToken];
                [[NSUserDefaults standardUserDefaults] synchronize];
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
                commonEventData.iOSVersion = @"1";
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
