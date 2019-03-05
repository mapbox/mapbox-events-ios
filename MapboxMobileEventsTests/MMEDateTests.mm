#import <Cedar/Cedar.h>
#import "MMEDate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEDateSpec)

describe(@"MMEDate", ^{

    NSTimeInterval const interval = 60; // just a minute

    context(@"+ recordTimeOffsetFromServer:", ^{
        it(@"computes offsets from server time", ^{
            NSDate* serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            NSTimeInterval recorded = [MMEDate recordTimeOffsetFromServer:serverTime];

            round(recorded) should equal(round(interval));
        });
    });

    context(@"+ recordedTimeOffsetFromServer:", ^{
        it(@"records computed offset from server time", ^{
            NSDate *serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            NSTimeInterval computed = [MMEDate recordTimeOffsetFromServer:serverTime];
            NSTimeInterval recorded = [MMEDate recordedTimeOffsetFromServer];

            round(computed) should equal(round(interval));
            round(recorded) should equal(round(interval));
        });
    });

    context(@"- initWithOffset:", ^{
        it(@"correctly records offsetFromServer", ^{
            MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

            offset.offsetFromServer should equal(interval);
        });
    });

    context(@"- offsetToServer:", ^{
        it(@"correctly computes offsetToServer date", ^{
            NSDate* serverTime = [NSDate dateWithTimeIntervalSinceNow:interval];
            MMEDate *offset = [MMEDate.alloc initWithOffset:interval];

            round(offset.offsetToServer.timeIntervalSinceReferenceDate) should equal(round(serverTime.timeIntervalSinceReferenceDate));
        });
    });

    context(@"+ iso8601DateFormatter stringFromDate:", ^{
        it(@"has the correct date format", ^{
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:213242];
            NSString *dateString = [MMEDate.iso8601DateFormatter stringFromDate:date];
            
            dateString should equal(@"1970-01-03T11:14:02.000+0000");
        });
    });

    context(@"- mme_oneDayLater", ^{
        it(@"should be less than 24 hours to the start of the next day", ^{
            MMEDate* now = MMEDate.date;
            NSDate* later = now.mme_startOfTomorrow;
            NSTimeInterval oneDay = (60 * 60 * 24); // S * M * H

            round(fabs([now timeIntervalSinceDate:later])) should be_less_than(oneDay);
        });
    });

    context(@"- NSCoding of MMEDate", ^{
        MMEDate* now = MMEDate.date;
        NSString* tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"MMEDate-now.data"];
        __block NSData* nowData = nil;

        beforeEach(^{
            if (@available(iOS 11.0, *)) {
                NSError* archiveError = nil;
                nowData = [NSKeyedArchiver archivedDataWithRootObject:now requiringSecureCoding:YES error:&archiveError];
                archiveError should equal(nil);
            }
        });

        it(@"should encode to data", ^{
            nowData.length should be_greater_than(0);
        });

        it(@"should decode from data", ^{
            if (@available(iOS 11.0, *)) {
                NSError* archiveError = nil;
                MMEDate* then = [NSKeyedUnarchiver unarchivedObjectOfClass:MMEDate.class fromData:nowData error:&archiveError];
                round(then.timeIntervalSinceReferenceDate) should equal(round(NSDate.timeIntervalSinceReferenceDate));
                archiveError should equal(nil);
            }
        });

        it(@"should write encoded data to a file", ^{
            [NSKeyedArchiver archiveRootObject:now toFile:tempFile];
            [NSFileManager.defaultManager fileExistsAtPath:tempFile] should equal(YES);
        });

        it(@"should read data and decode from a file", ^{
            MMEDate* then = [NSKeyedUnarchiver unarchiveObjectWithFile:tempFile];
            round(then.timeIntervalSinceReferenceDate) should equal(round(NSDate.timeIntervalSinceReferenceDate));
        });
    });

});

SPEC_END
