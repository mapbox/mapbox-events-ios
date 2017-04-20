#import "MMEEvent.h"
#import "MMEConstants.h"
#import "MMECommonEventData.h"

@implementation MMEEvent

+ (instancetype)locationEventWithAttributes:(MGLMapboxEventAttributes *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {

    MMEEvent *locationEvent = [[MMEEvent alloc] init];
    locationEvent.name = MMEEventTypeLocation;
    MGLMutableMapboxEventAttributes *commonAttributes = [NSMutableDictionary dictionary];
    commonAttributes[MMEEventKeyEvent] = locationEvent.name;
    commonAttributes[MMEEventKeySource] = MMEEventSource;
    commonAttributes[MMEEventKeySessionId] = instanceIdentifer;
    commonAttributes[MMEEventKeyOperatingSystem] = commonEventData.iOSVersion;
    NSString *applicationState = [commonEventData applicationState];
    if (![applicationState isEqualToString:MMEApplicationStateUnknown]) {
        commonAttributes[MMEEventKeyApplicationState] = applicationState;
    }
    [commonAttributes addEntriesFromDictionary:attributes];
    locationEvent.attributes = commonAttributes;
    return locationEvent;
}

@end
