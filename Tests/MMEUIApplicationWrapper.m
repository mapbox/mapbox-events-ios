#import <XCTest/XCTest.h>
#import <MapboxMobileEvents/MMEUIApplicationWrapper.h>

// MARK: - Mock Class
@interface MockApplicationWrapper: NSObject <MMEUIApplicationWrapper>

@property (nonatomic, assign) NSUInteger applicationStateCallCount;
@property (nonatomic, assign) NSUInteger beginBackgroundCallCount;
@property (nonatomic, assign) NSUInteger endBackgroundTaskCallCount;


@end

@implementation MockApplicationWrapper

- (NSInteger)mme_contentSizeScale {
    return 0;
}

- (UIApplicationState)applicationState {
    self.applicationStateCallCount += 1;
    return UIApplicationStateBackground;
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    self.beginBackgroundCallCount += 1;
    return 42;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    self.endBackgroundTaskCallCount += 1;
}

@end

// MARK: - Tests
@interface MMEUIApplicationWrapper (Private)
@property (nonatomic, strong) id <MMEUIApplicationWrapper> application;
@end

@interface MMEUIApplicationWrapperTests : XCTestCase
@property (nonatomic, strong) MockApplicationWrapper* mock;
@property (nonatomic, strong) MMEUIApplicationWrapper* application;
@end

@implementation MMEUIApplicationWrapperTests

- (void)setUp {
    self.mock = [[MockApplicationWrapper alloc] init];
    self.application = [[MMEUIApplicationWrapper alloc] initWithApplication:self.mock];
}

- (void)testDefaultInitializer {
    // Expect Wrapper to have a reference to shared application
    id <MMEUIApplicationWrapper> application = UIApplication.sharedApplication;
    XCTAssertEqual(MMEUIApplicationWrapper.new.application, application);
}
- (void)testDesignatedInitializer {
    MockApplicationWrapper *mock = [[MockApplicationWrapper alloc] init];
    MMEUIApplicationWrapper *wrapper = [[MMEUIApplicationWrapper alloc] initWithApplication:mock];
    XCTAssertEqual(wrapper.application, mock);
}

- (void)testApplicationState {
    XCTAssertEqual(self.application.applicationState, UIApplicationStateBackground);
    XCTAssertEqual(self.mock.applicationStateCallCount, 1);
}

- (void)testBeginBackgroundTask {
    XCTAssertEqual([self.application beginBackgroundTaskWithExpirationHandler:^{}], 42);
    XCTAssertEqual(self.mock.beginBackgroundCallCount, 1);
}

- (void)testEndBackgroundTask {
    [self.application endBackgroundTask:42];
    XCTAssertEqual(self.mock.endBackgroundTaskCallCount, 1);
}

@end
