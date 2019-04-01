#import <Cedar/Cedar.h>

#import "MMEDate.h"
#import "MMEEvent.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEEventSpec)

describe(@"MMEEvent", ^{
    NSString *testName = @"TestEventName";
    NSDictionary *testAttrs = @{@"AttributeName": @"AttributeValue"};

    context(@"eventWithName:attributes:", ^{
        NSDate *now = [NSDate date];
        MMEEvent *event = [MMEEvent eventWithName:testName attributes:testAttrs];

        it(@"should not be nil", ^{
            event should_not be_nil;
        });

        it(@"should have a date near now", ^{
            round(event.date.timeIntervalSinceReferenceDate) should equal(round(now.timeIntervalSinceReferenceDate));
        });

        it(@"should have the test event name", ^{
            event.name should equal(testName);
        });

        it(@"should have the test event attrs", ^{
            event.attributes should equal(testAttrs);
        });
    });

    context(@"NSSecureCoding of MMEEvent", ^{
        MMEEvent *event = [MMEEvent eventWithName:testName attributes:testAttrs];
        NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MMEEvent-test.data"];
        if ([NSFileManager.defaultManager fileExistsAtPath:tempFile]) {
            [NSFileManager.defaultManager removeItemAtPath:tempFile error:nil];
        }

        it(@"should archive to data", ^{
            NSKeyedArchiver *archiver = [NSKeyedArchiver new];
            archiver.requiresSecureCoding = YES;
            [archiver encodeObject:event forKey:NSKeyedArchiveRootObjectKey];
            NSData* eventData = archiver.encodedData;

            it(@"should encode to eventData", ^{
                eventData should_not be_nil;
                eventData.length should be_greater_than(0);
            });

            it(@"should decode from eventData", ^{
                NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:eventData];
                unarchiver.requiresSecureCoding = YES;
                MMEEvent *unarchived = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];

                unarchived should_not be_nil;
                unarchived should equal(event);
            });
        });

        it(@"should write encoded data to a file", ^{
            [NSKeyedArchiver archiveRootObject:event toFile:tempFile];
            [NSFileManager.defaultManager fileExistsAtPath:tempFile] should be_truthy;

            it(@"should read data and decode from a file", ^{
                NSData *thenData = [NSData dataWithContentsOfFile:tempFile];
                NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:thenData];
                unarchiver.requiresSecureCoding = YES;
                MMEEvent *unarchived = [unarchiver decodeObjectOfClass:MMEDate.class forKey:NSKeyedArchiveRootObjectKey];

                unarchived should_not be_nil;
                unarchived should equal(event);
            });
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

        it(@"should create an MMEEevent from a nil error", ^{
            MMEEvent *errorEventWithNilError = [MMEEvent debugEventWithError:nil];

            errorEventWithNilError should_not be_nil;
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
});

SPEC_END
