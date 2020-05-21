#import <XCTest/XCTest.h>

#import "MMEEvent.h"
#import "MMEEventFake.h"
#import "MMEExceptionalDictionary.h"

@interface MMEEvent (Tests)
+ (NSDictionary *)nilAttributes;
@end

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
    // Events without names should not be queued
    NSDictionary *attributes = @{@"attribute1": @"a nice attribute"};
    MMEEvent *event1 = [MMEEvent eventWithAttributes:attributes];
    MMEEvent *event2 = [MMEEvent eventWithAttributes:attributes];

    NSArray *eventQueue = [[NSArray alloc] initWithObjects:event1, event2, nil];

    XCTAssert(eventQueue.count == 0);
}

- (void)testEventWithNameAttributes {
    // Minimum
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

// MARK: - Coding / Decoding

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
     XCTAssertNotEqual(unarchived, event);
     XCTAssertEqualObjects(unarchived, event);
}

- (void)testNSSecuredDecodingOfMMEEvent {
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

- (void)testNSSecuredDecodingOfMMEEventFromFile {
    MMEEvent *event = [MMEEvent eventWithName:self.testName attributes:self.testAttrs];
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MMEEvent-test.data"];

    if ([NSFileManager.defaultManager fileExistsAtPath:tempFile]) {
        [NSFileManager.defaultManager removeItemAtPath:tempFile error:nil];
    }

    [NSKeyedArchiver archiveRootObject:event toFile:tempFile];

    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:tempFile]);

    NSData *thenData = [NSData dataWithContentsOfFile:tempFile];
    NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:thenData];
    unarchiver.requiresSecureCoding = YES;
    MMEEvent *unarchived = [unarchiver decodeObjectOfClass:MMEEvent.class forKey:NSKeyedArchiveRootObjectKey];

    XCTAssertNotNil(unarchived);
    XCTAssertEqualObjects(unarchived, event);

}

// MARK: - Nullable Initializer Checks

- (void)testErrorEventInitWithError {
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

    MMEEvent *errorEventWithNoInfo = [MMEEvent debugEventWithError:errorWithNoInfo];
    XCTAssertNotNil(errorEventWithNoInfo);

    MMEEvent *errorEventWithAllInfo = [MMEEvent debugEventWithError:errorWithAllInfo];
    XCTAssertNotNil(errorEventWithAllInfo);
}

-(void)testDebugEventWithException {
    NSException *exceptionWithNoInfo = [NSException exceptionWithName:NSGenericException reason:nil userInfo:nil];
    NSException *exceptionWithAllInfo = [NSException exceptionWithName:NSGenericException reason:@"TestReason" userInfo:@{
        @"ExceptionUserInfo": @"ExceptionUserInfo"
    }];

    // should create an MMEEvent from exceptionWithNoInfo
    MMEEvent *exceptionEventWithNoInfo = [MMEEvent debugEventWithException:exceptionWithNoInfo];
    XCTAssertNotNil(exceptionEventWithNoInfo);

    // should create an MMEEvent from exceptionWithAllInfo
    MMEEvent *exceptionEventWithAllInfo = [MMEEvent debugEventWithException:exceptionWithAllInfo];
    XCTAssertNotNil(exceptionEventWithAllInfo);
}

-(void)testEventInitWithInvalidAttributes {
    // Should not init with invalid attributes
    NSError *error = nil;
    MMEEvent *invalid = [MMEEvent eventWithAttributes:@{@"Invalid": [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]} error:&error];

    XCTAssertNil(invalid) ;
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MMEErrorEventInitInvalid);
}

-(void)testEventInitWithInitWthNilAttributes {
    // Should init with nil attributes for initWithCoder:", ^{
    NSError *error = nil;
    MMEEvent *invalid = [MMEEvent eventWithAttributes:MMEEvent.nilAttributes error:&error];

    XCTAssertNil(invalid.attributes);
    XCTAssertNil(error);
}

-(void)testInitWithoutEventKey {
    // Should not init without MMEEventKeyEvent
    NSError *error = nil;
    MMEEvent *invalid = [MMEEvent eventWithAttributes:@{@"foo":@"bar"} error:&error];

    XCTAssertNil(invalid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MMEErrorEventInitMissingKey);
}

-(void)testInitWithExceptionDictionary {
    // Should contain an exceptional dictionary
    NSError *error = nil;
    MMEEvent *exceptional = [MMEEvent eventWithAttributes:[MMEExceptionalDictionary dictionaryWithDictionary:@{MMEEventKeyEvent:@"exception"}] error:&error];
    XCTAssertNil(exceptional);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code,MMEErrorEventInitException);
}

-(void)testWithInvalidAttributes {
    MMEEvent *attributed = [MMEEvent eventWithAttributes:@{@"invalid":@"attributes"}];
    XCTAssertNil(attributed);
}

-(void)testInitWithCarplay {
    MMEEvent *carplay = [MMEEvent carplayEventWithName:MMEventTypeNavigationCarplayConnect attributes:self.testAttrs];
    XCTAssertNotNil(carplay);
}

// MARK: - Equatability

-(void)testEventEquatability {
    NSDictionary *eventAttributes = @{MMEEventKeyEvent: @"test.event"};
    MMEEvent *firstEvent = [MMEEvent eventWithAttributes:eventAttributes];
    MMEEvent *secondEvent = [MMEEvent eventWithAttributes:eventAttributes];


    XCTAssertNotNil(firstEvent);
    XCTAssertNotNil(secondEvent);
    XCTAssertEqualObjects(firstEvent, firstEvent);

    // should not be true for two consective events with the same attributes, or for nil
    XCTAssertNotEqual(firstEvent, secondEvent);

    // Should be false for an object of a different class
    XCTAssertNotEqualObjects(firstEvent, eventAttributes);
}

// MARK: - Hashable

-(void)testHash {
    // Should compute a non-0 hash
    MMEEvent *hashEvent = [MMEEvent eventWithAttributes:@{MMEEventKeyEvent: @"test.event"}];
    XCTAssertNotEqual(hashEvent.hash, 0);
}

// MARK: - NSCopying

-(void)testCopying {
    // Should create an isEqual: but not identity copy
    MMEEvent *original = [MMEEvent eventWithAttributes:@{MMEEventKeyEvent: @"test.event"}];
    MMEEvent *duplicate = original.copy;

    XCTAssertEqualObjects(original, duplicate);
    XCTAssertNotEqual(original, duplicate);
}

@end
