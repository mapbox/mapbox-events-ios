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
    
    describe(@"- testing API setup", ^{
        context(@"when MMETelemetryTestServerURL is nil", ^{
            
            beforeEach(^{
                spy_on([NSUserDefaults standardUserDefaults]);
                [NSUserDefaults standardUserDefaults] stub_method(@selector(objectForKey:)).with(MMETelemetryTestServerURL).and_return(nil);
                
                apiClient = [[MMEAPIClient alloc] initWithAccessToken:@"access-token"
                                                        userAgentBase:@"user-agent-base"
                                                       hostSDKVersion:@"host-sdk-1"];
                
                apiClient.sessionWrapper should_not be_nil;
            });
            
            it(@"should equal the BaseURL constant", ^{
                apiClient.baseURL should equal([NSURL URLWithString:MMEAPIClientBaseURL]);
            });
            
            afterEach(^{
                stop_spying_on([NSUserDefaults standardUserDefaults]);
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
            
            it(@"should equal the BaseURL constant", ^{
                apiClient.baseURL should equal([NSURL URLWithString:testURLString]);
            });
            
            afterEach(^{
                stop_spying_on([NSUserDefaults standardUserDefaults]);
            });
        });
        
        context(@"when a bad URL is added to MMETelemetryTestServerURL", ^{
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
    
    describe(@"- Posting events", ^{
        __block MMEEvent *event;
        __block MMEAPIClientFake *apiClientFake;
        
        beforeEach(^{
            
            MMENSURLSessionWrapperFake *sessionWrapperFake = [[MMENSURLSessionWrapperFake alloc] init];
            apiClient.sessionWrapper = sessionWrapperFake;
//            apiClientFake.accessToken = @"an-access-token";
            
            apiClientFake = [[MMEAPIClientFake alloc] init];
            spy_on(apiClientFake);
            
            apiClientFake.accessToken = @"access-token";
            apiClientFake.userAgentBase = @"user-agent-base";
            apiClientFake.hostSDKVersion = @"host-sdk-version";
            
            MMECommonEventData *commonEventData = [[MMECommonEventData alloc] init];
            commonEventData.vendorId = @"vendor-id";
            commonEventData.model = @"model";
            commonEventData.iOSVersion = @"1";
            commonEventData.scale = 42;
            
            event = [MMEEvent locationEventWithAttributes:@{} instanceIdentifer:@"instance-id-1" commonEventData:commonEventData];
        });
        
        context(@"when posting a single event", ^{
            
            it(@"should recieve a single post event", ^{
                apiClientFake should have_received(@selector(postEvent:completionHandler:)).with(event).and_with(Arguments::anything);
            });
            
        });
        
    });
    

});

SPEC_END
