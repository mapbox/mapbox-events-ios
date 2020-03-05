#import <XCTest/XCTest.h>

#import "MMELogger.h"

@interface MMELoggerTests : XCTestCase
@property(nonatomic,retain) MMELogger *testLogger;

@end

// MARK: -

@implementation MMELoggerTests

- (void)setUp {
    self.testLogger = MMELogger.new;
}

- (void)tearDown {
}

- (void)test0001_level_none {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogNone);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogNone withType:@"Test" andMessage:@"MMELogNone"];
}

- (void)test0002_level_fatal {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogFatal);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogFatal withType:@"Test" andMessage:@"MMELogFatal"];
}

- (void)test0003_level_error {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogError);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogError withType:@"Test" andMessage:@"MMELogError"];
}

- (void)test0004_level_warn {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogWarn);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogWarn withType:@"Test" andMessage:@"MMELogWarn"];
}

- (void)test0005_level_info {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogInfo);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogInfo withType:@"Test" andMessage:@"MMELogInfo"];
}

- (void)test0006_level_event {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogEvent);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogEvent withType:@"Test" andMessage:@"MMELogEvent"];
}

- (void)test0007_level_network {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogNetwork);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogNetwork withType:@"Test" andMessage:@"MMELogNetwork"];
}

- (void)test0008_level_network {
    MMELoggingBlockHandler testHandler = ^(MMELogLevel level, NSString *type, NSString *message) {
        XCTAssert(level == MMELogDebug);
    };
    self.testLogger.handler = testHandler;
    [self.testLogger logPriority:MMELogDebug withType:@"Test" andMessage:@"MMELogDebug"];
}

@end
