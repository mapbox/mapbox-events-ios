#import <XCTest/XCTest.h>

#import "MMEEvent.h"
#import "MMEEventFake.h"

@interface MMEEventTests : XCTestCase
@property(nonatomic,retain) NSString *testName;
@property(nonatomic,retain) NSDictionary *testAttrs;

@end

// MARK: -

@implementation MMEEventTests

- (void)setUp {
    self.testName = @"TestEventName";
    self.testAttrs = @{@"AttributeName": @"AttributeValue"};
}

- (void)testEventsWithoutName {
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent eventWithAttributes:attributes];
    MMEEvent *event2 = [MMEEvent eventWithAttributes:attributes];

    NSArray *eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];

    XCTAssert(eventQueue.count == 0);
}

- (void)testEventWithNameAttributes {
    NSDate *now = [NSDate date];
    MMEEvent *event = [MMEEvent eventWithName:self.testName attributes:self.testAttrs];

    // it(@"should not be nil", ^{
    XCTAssertNotNil(event);

    // it(@"should have a date near now", ^{
    XCTAssert(lround(event.date.timeIntervalSinceReferenceDate) == lround(now.timeIntervalSinceReferenceDate));

    // it(@"should have the test event name", ^{
    XCTAssert([event.name isEqualToString:self.testName]);

    // it(@"should have all the test event attrs", ^{
    for (NSString *key in self.testAttrs.allKeys) {
        id value = event.attributes[key];
        XCTAssertNotNil(value);
        XCTAssert(self.testAttrs[key] == value);
    }
}

- (void)testNSSecureCodingOfMMEEvent {
     MMEEvent *event = [MMEEvent eventWithName:self.testName attributes:self.testAttrs];
     NSKeyedArchiver *archiver = [NSKeyedArchiver new];
     archiver.requiresSecureCoding = YES;
     [archiver encodeObject:event forKey:NSKeyedArchiveRootObjectKey];
     NSData *eventData = archiver.encodedData;

     // it should encode to eventData
     XCTAssertNotNil(eventData);
     XCTAssert(eventData.length > 0);

     // it should decode from eventData
     NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:eventData];
     unarchiver.requiresSecureCoding = YES;
     MMEEvent *unarchived = [unarchiver decodeObjectOfClass:MMEEvent.class forKey:NSKeyedArchiveRootObjectKey];

     XCTAssertNotNil(unarchived);
     XCTAssertEqualObjects(unarchived, event);
}

- (void)testNSSecuredDecodeingOfMMEEvent {
     // uses MMEEventFake to override `encodeWithCoder:`
     MMEEventFake *futureVersionEvent = [MMEEventFake eventWithName:self.testName attributes:self.testAttrs];
         
     NSKeyedArchiver *archiver = NSKeyedArchiver.new;
     archiver.requiresSecureCoding = YES;
     [archiver encodeObject:futureVersionEvent forKey:NSKeyedArchiveRootObjectKey];
     NSData *eventData = archiver.encodedData;
         
     NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:eventData];
     unarchiver.requiresSecureCoding = YES;
         
     MMEEventFake *unarchived = [unarchiver decodeObjectOfClass:MMEEventFake.class forKey:NSKeyedArchiveRootObjectKey];
     XCTAssertNil(unarchived);
}

// TODO: Convert Cedar Tests

/*

 context(@"NSKeyedArchiver", ^{
     MMEEvent *event = [MMEEvent eventWithName:testName attributes:testAttrs];
     NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MMEEvent-test.data"];

     if ([NSFileManager.defaultManager fileExistsAtPath:tempFile]) {
         [NSFileManager.defaultManager removeItemAtPath:tempFile error:nil];
     }

     [NSKeyedArchiver archiveRootObject:event toFile:tempFile];

     it(@"should write encoded data to a file", ^{
         [NSFileManager.defaultManager fileExistsAtPath:tempFile] should be_truthy;
     });

     it(@"should read encoded data from a file", ^{
         NSData *thenData = [NSData dataWithContentsOfFile:tempFile];
         NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:thenData];
         unarchiver.requiresSecureCoding = YES;
         MMEEvent *unarchived = [unarchiver decodeObjectOfClass:MMEEvent.class forKey:NSKeyedArchiveRootObjectKey];

         unarchived should_not be_nil;
         unarchived should equal(event);
     });
 });

 context(@"debugEventWithError", ^{
     NSError *errorWithNoInfo = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
     NSError *errorWithAllInfo = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{
         NSURLErrorKey: [NSURL URLWithString:@"http://mapbox.com"],
         NSHelpAnchorErrorKey: @"NSHelpAnchorErrorKey",
         NSLocalizedDescriptionKey: @"NSLocalizedDescriptionKey",
         NSLocalizedFailureReasonErrorKey: @"NSLocalizedFailureReasonErrorKey",
         NSLocalizedRecoveryOptionsErrorKey: @[@"Abort", @"Retry", @"Fail"],
         NSLocalizedRecoverySuggestionErrorKey: @"NSLocalizedRecoverySuggestionErrorKey",
         NSStringEncodingErrorKey: @(NSUTF8StringEncoding),
         NSUnderlyingErrorKey: errorWithNoInfo,
         NSDebugDescriptionErrorKey: @"PC LOAD LETTER"
     }];

     it(@"should create an MMEEvent from errorWithNoInfo", ^{
         MMEEvent *errorEventWithNoInfo = [MMEEvent debugEventWithError:errorWithNoInfo];
         errorEventWithNoInfo should_not be_nil;
     });

     it(@"should crteate an MMEEvent from errorWithAllInfo", ^{
         MMEEvent *errorEventWithAllInfo = [MMEEvent debugEventWithError:errorWithAllInfo];
         errorEventWithAllInfo should_not be_nil;
     });
 });

 context(@"debugEventWithException", ^{
     NSException *exceptionWithNoInfo = [NSException exceptionWithName:NSGenericException reason:nil userInfo:nil];
     NSException *exceptionWithAllInfo = [NSException exceptionWithName:NSGenericException reason:@"TestReason" userInfo:@{
         @"ExceptionUserInfo": @"ExceptionUserInfo"
     }];

     it(@"should create an MMEEvent from exceptionWithNoInfo", ^{
         MMEEvent *exceptionEventWithNoInfo = [MMEEvent debugEventWithException:exceptionWithNoInfo];
         exceptionEventWithNoInfo should_not be_nil;
     });

     it(@"should create an MMEEvent from exceptionWithAllInfo", ^{
         MMEEvent *exceptionEventWithAllInfo = [MMEEvent debugEventWithException:exceptionWithAllInfo];
         exceptionEventWithAllInfo should_not be_nil;
     });
 });

 context(@"eventWithAttributes:error:", ^{
     it(@"should not init with invalid attributes", ^{
         NSError *error = nil;
         MMEEvent *invalid = [MMEEvent eventWithAttributes:@{@"Invalid": [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]} error:&error];

         invalid should be_nil;
         error should_not be_nil;
         error.code should equal(MMEErrorEventInitInvalid);
     });

     it(@"should init with nil attributes for initWithCoder:", ^{
         NSError *error = nil;
         MMEEvent *invalid = [MMEEvent eventWithAttributes:MMEEvent.nilAttributes error:&error];

         invalid.attributes should be_nil;
         error should be_nil;
     });

     it(@"should not init without MMEEventKeyEvent", ^{
         NSError *error = nil;
         MMEEvent *invalid = [MMEEvent eventWithAttributes:@{@"foo":@"bar"} error:&error];

         invalid should be_nil;
         error should_not be_nil;
         error.code should equal(MMEErrorEventInitMissingKey);
     });

     it(@"should contain an exceptional dictionary", ^{
         NSError *error = nil;
         MMEEvent *exceptional = [MMEEvent eventWithAttributes:[MMEExceptionalDictionary dictionaryWithDictionary:@{MMEEventKeyEvent:@"exception"}] error:&error];

         exceptional should be_nil;
         error should_not be_nil;
         error.code should equal(MMEErrorEventInitException);
     });
 });

 context(@"eventWithAttributes:", ^{
     MMEEvent *attributed = [MMEEvent eventWithAttributes:@{@"invalid":@"attributes"}];

     it(@"should return nil with invalid attributes:", ^{
         attributed should be_nil;
     });
 });

 context(@"carplayEvent", ^{
     MMEEvent *carplay = [MMEEvent carplayEventWithName:MMEventTypeNavigationCarplayConnect attributes:testAttrs];

     it(@"should create a carplay event", ^{
         carplay should_not be_nil;
     });
 });

 context(@"isEqualToEvent:", ^{
     NSDictionary *eventAttributes = @{MMEEventKeyEvent: @"test.event"};
     MMEEvent *firstEvent = [MMEEvent eventWithAttributes:eventAttributes];
     MMEEvent *secondEvent = [MMEEvent eventWithAttributes:eventAttributes];

     it(@"should not be true for two consective events with the same attributes, or for nil", ^{
         [firstEvent isEqual:secondEvent] should_not be_truthy;
     });

     it(@"should be false for nil", ^{
         [firstEvent isEqual:nil] should_not be_truthy;
     });

     it(@"should be true in the identity case", ^{
         [firstEvent isEqual:firstEvent] should be_truthy;
     });

     it(@"should be false for an object of a different class", ^{
         [firstEvent isEqual:eventAttributes] should_not be_truthy;
     });
 });

 context(@"hash:", ^{
     it(@"should compute a non-0 hash", ^{
         MMEEvent *hashEvent = [MMEEvent eventWithAttributes:@{MMEEventKeyEvent: @"test.event"}];
         NSUInteger hashcode = hashEvent.hash;

         hashcode should_not equal(0);
     });
 });

 context(@"NSCopying", ^{
     it(@"should create an isEqual: but not identity copy", ^{
         MMEEvent *original = [MMEEvent eventWithAttributes:@{MMEEventKeyEvent: @"test.event"}];
         MMEEvent *duplicate = original.copy;

         [original isEqual:duplicate] should be_truthy;
         (original == duplicate) should_not be_truthy;
     });
 });
*/

@end
