#import "MMEConstants.h"

NSString * const MMEAPIClientAttachmentsHeaderFieldContentTypeValue = @"multipart/form-data";
NSString * const MMEAPIClientAttachmentsPath = @"attachments/v1";
NSString * const MMEAPIClientBaseAPIURL = @"https://api.mapbox.com";
NSString * const MMEAPIClientBaseURL = @"https://events.mapbox.com";
NSString * const MMEAPIClientBaseChinaAPIURL = @"https://api.mapbox.cn";
NSString * const MMEAPIClientBaseChinaEventsURL = @"https://events.mapbox.cn";
NSString * const MMEAPIClientEventsConfigPath = @"events-config";
NSString * const MMEAPIClientEventsPath = @"events/v2";
NSString * const MMEAPIClientHeaderFieldContentEncodingKey = @"Content-Encoding";
NSString * const MMEAPIClientHeaderFieldContentTypeKey = @"Content-Type";
NSString * const MMEAPIClientHeaderFieldContentTypeValue = @"application/json";
NSString * const MMEAPIClientHeaderFieldUserAgentKey = @"User-Agent";
NSString * const MMEAPIClientHTTPMethodGet = @"GET";
NSString * const MMEAPIClientHTTPMethodPost = @"POST";
NSString * const MMEErrorDomain = @"MMEErrorDomain";

// Debug types
NSString * const MMEDebugEventTypeBackgroundTask = @"backgroundTask";
NSString * const MMEDebugEventTypeFlush = @"flush";
NSString * const MMEDebugEventTypeLocationManager = @"locationManager";
NSString * const MMEDebugEventTypeMetricCollection = @"metricCollection";
NSString * const MMEDebugEventTypePush = @"push";
NSString * const MMEDebugEventTypePost = @"post";
NSString * const MMEDebugEventTypePostFailed = @"postFailed";
NSString * const MMEDebugEventTypeTurnstile = @"turnstile";
NSString * const MMEDebugEventTypeTurnstileFailed = @"turnstileFailed";

// Event prefixes
NSString * const MMENavigationEventPrefix = @"navigation.";
NSString * const MMESearchEventPrefix = @"search.";
NSString * const MMEVisionEventPrefix = @"vision.";

// Event types
NSString * const MMEDebugEventType = @"debug.type";
NSString * const MMEEventTypeAppUserTurnstile = @"appUserTurnstile";
NSString * const MMEEventTypeLocalDebug = @"debug";
NSString * const MMEEventTypeLocation = @"location";
NSString * const MMEEventTypeMapDragEnd = @"map.dragend";
NSString * const MMEEventTypeMapLoad = @"map.load";
NSString * const MMEEventTypeMapTap = @"map.click";
NSString * const MMEEventTypeNavigationArrive = @"navigation.arrive";
NSString * const MMEEventTypeNavigationCancel = @"navigation.cancel";
NSString * const MMEEventTypeNavigationDepart = @"navigation.depart";
NSString * const MMEEventTypeNavigatonFeedback = @"navigation.feedback";
NSString * const MMEEventTypeNavigationReroute = @"navigation.reroute";
NSString * const MMEEventTypeSearchFeedback = @"search.feedback";
NSString * const MMEEventTypeSearchSelected = @"search.selected";
NSString * const MMEventTypeNavigationCarplayConnect = @"navigation.carplay.connect";
NSString * const MMEventTypeNavigationCarplayDisconnect = @"navigation.carplay.disconnect";
NSString * const MMEventTypeOfflineDownloadStart = @"map.offlineDownload.start";
NSString * const MMEventTypeOfflineDownloadEnd = @"map.offlineDownload.end";
NSString * const MMEEventTypeVisit = @"visit";

// Gestures
NSString * const MMEEventGestureDoubleTap = @"DoubleTap";
NSString * const MMEEventGesturePanStart = @"Pan";
NSString * const MMEEventGesturePitchStart = @"Pitch";
NSString * const MMEEventGesturePinchStart = @"Pinch";
NSString * const MMEEventGestureQuickZoom = @"QuickZoom";
NSString * const MMEEventGestureRotateStart = @"Rotation";
NSString * const MMEEventGestureSingleTap = @"SingleTap";
NSString * const MMEEventGestureTwoFingerSingleTap = @"TwoFingerTap";

// Event keys
NSString * const MMEEventKeyAccessibilityFontScale = @"accessibilityFontScale";
NSString * const MMEEventKeyAltitude = @"altitude";
NSString * const MMEEventKeyApplicationState = @"applicationState";
NSString * const MMEEventKeyArrivalDate = @"arrivalDate";
NSString * const MMEEventKeyCourse = @"course";
NSString * const MMEEventKeyCreated = @"created";
NSString * const MMEEventKeyDepartureDate = @"departureDate";
NSString * const MMEEventKeyDevice = @"device";
NSString * const MMEEventKeyEnabledTelemetry = @"enabled.telemetry";
NSString * const MMEEventKeyEvent = @"event";
NSString * const MMEEventKeyGestureID = @"gesture";
NSString * const MMEEventHorizontalAccuracy = @"horizontalAccuracy";
NSString * const MMEEventKeyLatitude = @"lat";
NSString * const MMEEventKeyLocalDebugDescription = @"debug.description";
NSString * const MMEEventKeyLongitude = @"lng";
NSString * const MMEEventKeyModel = @"model";
NSString * const MMEEventKeyOperatingSystem = @"operatingSystem";
NSString * const MMEEventKeyOrientation = @"orientation";
NSString * const MMEEventKeyPluggedIn = @"pluggedIn";
NSString * const MMEEventKeyResolution = @"resolution";
NSString * const MMEEventKeySessionId = @"sessionId";
NSString * const MMEEventKeyShapeForOfflineRegion = @"shapeForOfflineRegion";
NSString * const MMEEventKeySource = @"source";
NSString * const MMEEventKeySpeed = @"speed";
NSString * const MMEEventKeyVendorID = @"userId";
NSString * const MMEEventKeyWifi = @"wifi";
NSString * const MMEEventKeyZoomLevel = @"zoom";
NSString * const MMEEventSDKIdentifier = @"sdkIdentifier";
NSString * const MMEEventSDKVersion = @"sdkVersion";

// SDK event source
NSString * const MMEEventSource = @"mapbox";

// Log reporter HTML
NSString * const MMELoggerHTML = @"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});var container = document.getElementById('timeline-tooltip');var dataString;function addData(data) {dataString = data}window.webkit.messageHandlers.data.postMessage('data');google.charts.setOnLoadCallback(drawChart); function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'instance', type: 'string'},{type: 'string', role: 'tooltip', p:{html:true}},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: dataString});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true },tooltip: {isHtml: true}};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));google.visualization.events.addListener(chart, 'ready', afterDraw);chart.draw(dataTable, options);}function afterDraw() {window.webkit.messageHandlers.complete.postMessage('complete');}</script></head><body><div id=\"timeline-tooltip\" style=\"height: 180px;\"></div><div id='chart_div'></div></body></html>";

NSString * const MMELoggerShareableHTML = @"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});var container = document.getElementById('timeline-tooltip');var dataString;function addData(data) {dataString = data};google.charts.setOnLoadCallback(drawChart); function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'instance', type: 'string'},{type: 'string', role: 'tooltip', p:{html:true}},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: dataString});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true },tooltip: {isHtml: true}};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));google.visualization.events.addListener(chart, 'ready', afterDraw);chart.draw(dataTable, options);}function afterDraw() {}</script></head><body><div id=\"timeline-tooltip\" style=\"height: 180px;\"></div><div id='chart_div'></div></body></html>";

@implementation MMEConstants

@end
