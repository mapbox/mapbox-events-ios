#import "MMEConstants.h"

NSString * const MMEAPIClientBaseURL = @"https://events.mapbox.com";
NSString * const MMETelemetryTestServerURL = @"MGLTelemetryTestServerURL";

NSString * const MMEEventTypeAppUserTurnstile = @"appUserTurnstile";
NSString * const MMEEventTypeMapLoad = @"map.load";
NSString * const MMEEventTypeMapTap = @"map.click";
NSString * const MMEEventTypeMapDragEnd = @"map.dragend";
NSString * const MMEEventTypeLocation = @"location";
NSString * const MMEEventTypeLocalDebug = @"debug";

NSString * const MMEEventGestureSingleTap = @"SingleTap";
NSString * const MMEEventGestureDoubleTap = @"DoubleTap";
NSString * const MMEEventGestureTwoFingerSingleTap = @"TwoFingerTap";
NSString * const MMEEventGestureQuickZoom = @"QuickZoom";
NSString * const MMEEventGesturePanStart = @"Pan";
NSString * const MMEEventGesturePinchStart = @"Pinch";
NSString * const MMEEventGestureRotateStart = @"Rotation";
NSString * const MMEEventGesturePitchStart = @"Pitch";

NSString * const MMEEventKeyLatitude = @"lat";
NSString * const MMEEventKeyLongitude = @"lng";
NSString * const MMEEventKeyZoomLevel = @"zoom";
NSString * const MMEEventKeySpeed = @"speed";
NSString * const MMEEventKeyCourse = @"course";
NSString * const MMEEventKeyGestureID = @"gesture";
NSString * const MMEEventHorizontalAccuracy = @"horizontalAccuracy";
NSString * const MMEEventKeyLocalDebugDescription = @"debug.description";
NSString * const MMEEventKeyEvent = @"event";
NSString * const MMEEventKeyCreated = @"created";
NSString * const MMEEventKeyVendorID = @"userId";
NSString * const MMEEventKeyModel = @"model";
NSString * const MMEEventKeyEnabledTelemetry = @"enabled.telemetry";
NSString * const MMEEventKeyOperatingSystem = @"operatingSystem";
NSString * const MMEEventKeyResolution = @"resolution";
NSString * const MMEEventKeyAccessibilityFontScale = @"accessibilityFontScale";
NSString * const MMEEventKeyOrientation = @"orientation";
NSString * const MMEEventKeyPluggedIn = @"pluggedIn";
NSString * const MMEEventKeyWifi = @"wifi";
NSString * const MMEEventKeySource = @"source";
NSString * const MMEEventKeySessionId = @"sessionId";
NSString * const MMEEventKeyApplicationState = @"applicationState";
NSString * const MMEEventKeyAltitude = @"altitude";

NSString * const MMEEventSource = @"mapbox";

@implementation MMEConstants

@end
