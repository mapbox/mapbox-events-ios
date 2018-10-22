#import <Foundation/Foundation.h>

extern NSString * const MMEAPIClientAttachmentsHeaderFieldContentTypeValue;
extern NSString * const MMEAPIClientAttachmentsPath;
extern NSString * const MMEAPIClientBaseAPIURL;
extern NSString * const MMEAPIClientBaseURL;
extern NSString * const MMEAPIClientBaseChinaAPIURL;
extern NSString * const MMEAPIClientBaseChinaEventsURL;
extern NSString * const MMEAPIClientEventsConfigPath;
extern NSString * const MMEAPIClientEventsPath;
extern NSString * const MMEAPIClientHeaderFieldContentEncodingKey;
extern NSString * const MMEAPIClientHeaderFieldContentTypeKey;
extern NSString * const MMEAPIClientHeaderFieldContentTypeValue;
extern NSString * const MMEAPIClientHeaderFieldUserAgentKey;
extern NSString * const MMEAPIClientHTTPMethodGet;
extern NSString * const MMEAPIClientHTTPMethodPost;
extern NSString * const MMEErrorDomain;

// Debug types
extern NSString * const MMEDebugEventTypeBackgroundTask;
extern NSString * const MMEDebugEventTypeFlush;
extern NSString * const MMEDebugEventTypeLocationManager;
extern NSString * const MMEDebugEventTypeMetricCollection;
extern NSString * const MMEDebugEventTypePush;
extern NSString * const MMEDebugEventTypePost;
extern NSString * const MMEDebugEventTypePostFailed;
extern NSString * const MMEDebugEventTypeTurnstile;
extern NSString * const MMEDebugEventTypeTurnstileFailed;

// Event prefixes
extern NSString * const MMENavigationEventPrefix;
extern NSString * const MMESearchEventPrefix;
extern NSString * const MMEVisionEventPrefix;

// Event types
extern NSString * const MMEDebugEventType;
extern NSString * const MMEEventTypeAppUserTurnstile;
extern NSString * const MMEEventTypeLocalDebug;
extern NSString * const MMEEventTypeLocation;
extern NSString * const MMEEventTypeMapDragEnd;
extern NSString * const MMEEventTypeMapLoad;
extern NSString * const MMEEventTypeMapTap;
extern NSString * const MMEEventTypeNavigationArrive;
extern NSString * const MMEEventTypeNavigationCancel;
extern NSString * const MMEEventTypeNavigationDepart;
extern NSString * const MMEEventTypeNavigationFeedback;
extern NSString * const MMEEventTypeNavigationReroute;
extern NSString * const MMEEventTypeSearchFeedback;
extern NSString * const MMEEventTypeSearchSelected;
extern NSString * const MMEventTypeNavigationCarplayConnect;
extern NSString * const MMEventTypeNavigationCarplayDisconnect;
extern NSString * const MMEventTypeOfflineDownloadStart;
extern NSString * const MMEventTypeOfflineDownloadEnd;
extern NSString * const MMEEventTypeVisit;

// Gestures
extern NSString * const MMEEventGestureDoubleTap;
extern NSString * const MMEEventGesturePanStart;
extern NSString * const MMEEventGesturePitchStart;
extern NSString * const MMEEventGesturePinchStart;
extern NSString * const MMEEventGestureQuickZoom;
extern NSString * const MMEEventGestureRotateStart;
extern NSString * const MMEEventGestureSingleTap;
extern NSString * const MMEEventGestureTwoFingerSingleTap;

// Event keys
extern NSString * const MMEEventKeyAccessibilityFontScale;
extern NSString * const MMEEventKeyAltitude;
extern NSString * const MMEEventKeyApplicationState;
extern NSString * const MMEEventKeyArrivalDate;
extern NSString * const MMEEventKeyCourse;
extern NSString * const MMEEventKeyCreated;
extern NSString * const MMEEventKeyDepartureDate;
extern NSString * const MMEEventKeyDevice;
extern NSString * const MMEEventKeyEnabledTelemetry;
extern NSString * const MMEEventKeyEvent;
extern NSString * const MMEEventKeyGestureID;
extern NSString * const MMEEventHorizontalAccuracy;
extern NSString * const MMEEventKeyLatitude;
extern NSString * const MMEEventKeyLocalDebugDescription;
extern NSString * const MMEEventKeyLongitude;
extern NSString * const MMEEventKeyModel;
extern NSString * const MMEEventKeyOperatingSystem;
extern NSString * const MMEEventKeyOrientation;
extern NSString * const MMEEventKeyPluggedIn;
extern NSString * const MMEEventKeyResolution;
extern NSString * const MMEEventKeySessionId;
extern NSString * const MMEEventKeyShapeForOfflineRegion;
extern NSString * const MMEEventKeySource;
extern NSString * const MMEEventKeySpeed;
extern NSString * const MMEEventKeyVendorID;
extern NSString * const MMEEventKeyWifi;
extern NSString * const MMEEventKeyZoomLevel;
extern NSString * const MMEEventSDKIdentifier;
extern NSString * const MMEEventSDKVersion;

// SDK event source
extern NSString * const MMEEventSource;

// Log reporter HTML
extern NSString * const MMELoggerHTML;
extern NSString * const MMELoggerShareableHTML;

@interface MMEConstants: NSObject

@end
