#import "MMEEvent.h"
#import "MMEConstants.h"
#import "MMECommonEventData.h"

@implementation MMEEvent

+ (instancetype)turnstileEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *turnstileEvent = [[MMEEvent alloc] init];
    turnstileEvent.name = MMEEventTypeAppUserTurnstile;
    turnstileEvent.attributes = attributes;
    return turnstileEvent;
}

+ (instancetype)locationEventWithAttributes:(NSDictionary *)attributes instanceIdentifer:(NSString *)instanceIdentifer commonEventData:(MMECommonEventData *)commonEventData {

    MMEEvent *locationEvent = [[MMEEvent alloc] init];
    locationEvent.name = MMEEventTypeLocation;
    NSMutableDictionary *commonAttributes = [NSMutableDictionary dictionary];
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

+ (instancetype)debugEventWithAttributes:(NSDictionary *)attributes {
    MMEEvent *debugEvent = [[MMEEvent alloc] init];
    debugEvent.name = MMEEventTypeLocalDebug;
    debugEvent.attributes = [attributes copy];
    return debugEvent;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, attributes=%@>", NSStringFromClass([self class]), self.name, self.attributes];
}

@end
