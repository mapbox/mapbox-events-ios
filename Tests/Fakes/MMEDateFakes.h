#import "MMEDate.h"

NS_ASSUME_NONNULL_BEGIN

/** some fake dates with sloppy matching for testing MMEEvents */
@interface MMEDateFakes : MMEDate

/** an MMEDate which isEqual: and can compare: as equal to any date which is earlier on the timeline than it's creation */
+ (MMEDate *)earlier;

/** an MMEDate which isEqual: to and can compare: as equal to any date which is later on the timeline than it's creation */
+ (MMEDate *)later;

/** an MMEDate which isEqual: to all NSDates and will compare: as equal to any date */
+ (MMEDate *)whenever;

/** an MMEDate which never isEqual: to any date and will never compare: as equal to any date */
+ (MMEDate *)never;

@end

NS_ASSUME_NONNULL_END
