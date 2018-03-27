#import "MMEConstants.h"

NSString * const MMEAPIClientBaseURL = @"https://events.mapbox.com";
NSString * const MMEAPIClientEventsPath = @"events/v2";
NSString * const MMEAPIClientHeaderFieldUserAgentKey = @"User-Agent";
NSString * const MMEAPIClientHeaderFieldContentTypeKey = @"Content-Type";
NSString * const MMEAPIClientHeaderFieldContentTypeValue = @"application/json";
NSString * const MMEAPIClientHeaderFieldContentEncodingKey = @"Content-Encoding";
NSString * const MMEAPIClientHTTPMethodPost = @"POST";
NSString * const MMEErrorDomain = @"MMEErrorDomain";

NSString * const MMEDebugEventTypeFlush = @"flush";
NSString * const MMEDebugEventTypePush = @"push";
NSString * const MMEDebugEventTypePost = @"post";
NSString * const MMEDebugEventTypePostFailed = @"postFailed";
NSString * const MMEDebugEventTypeTurnstile = @"turnstile";
NSString * const MMEDebugEventTypeTurnstileFailed = @"turnstileFailed";
NSString * const MMEDebugEventTypeBackgroundTask = @"backgroundTask";
NSString * const MMEDebugEventTypeMetricCollection = @"metricCollection";
NSString * const MMEDebugEventTypeLocationManager = @"locationManager";

NSString * const MMEEventTypeAppUserTurnstile = @"appUserTurnstile";
NSString * const MMEEventTypeMapLoad = @"map.load";
NSString * const MMEEventTypeMapTap = @"map.click";
NSString * const MMEEventTypeMapDragEnd = @"map.dragend";
NSString * const MMEEventTypeLocation = @"location";
NSString * const MMEEventTypeVisit = @"visit";
NSString * const MMEEventTypeLocalDebug = @"debug";

NSString * const MMEEventGestureSingleTap = @"SingleTap";
NSString * const MMEEventGestureDoubleTap = @"DoubleTap";
NSString * const MMEEventGestureTwoFingerSingleTap = @"TwoFingerTap";
NSString * const MMEEventGestureQuickZoom = @"QuickZoom";
NSString * const MMEEventGesturePanStart = @"Pan";
NSString * const MMEEventGesturePinchStart = @"Pinch";
NSString * const MMEEventGestureRotateStart = @"Rotation";
NSString * const MMEEventGesturePitchStart = @"Pitch";

NSString * const MMEEventKeyArrivalDate = @"arrivalDate";
NSString * const MMEEventKeyDepartureDate = @"departureDate";
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
NSString * const MMEEventKeyDevice = @"device";
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
NSString * const MMEEventSDKIdentifier = @"sdkIdentifier";
NSString * const MMEEventSDKVersion = @"sdkVersion";
NSString * const MMENavigationEventPrefix = @"navigation.";
NSString * const MMEEventTypeNavigationDepart = @"navigation.depart";
NSString * const MMEEventTypeNavigationArrive = @"navigation.arrive";
NSString * const MMEEventTypeNavigationCancel = @"navigation.cancel";
NSString * const MMEEventTypeNavigationFeedback = @"navigation.feedback";
NSString * const MMEEventTypeNavigationReroute = @"navigation.reroute";
NSString * const MMEDebugEventType = @"debug.type";

NSString * const MMEEventSource = @"mapbox";

NSString * const MMELoggerHTML = @"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});var container = document.getElementById('timeline-tooltip');var dataString;function addData(data) {dataString = data}window.webkit.messageHandlers.data.postMessage('data');google.charts.setOnLoadCallback(drawChart); function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'instance', type: 'string'},{type: 'string', role: 'tooltip', p:{html:true}},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: dataString});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true },tooltip: {isHtml: true}};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));google.visualization.events.addListener(chart, 'ready', afterDraw);chart.draw(dataTable, options);}function afterDraw() {window.webkit.messageHandlers.complete.postMessage('complete');}</script></head><body><div id=\"timeline-tooltip\" style=\"height: 180px;\"></div><div id='chart_div'></div></body></html>";

NSString * const MMELoggerShareableHTML = @"<html><head><script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script><script type='text/javascript'>google.charts.load('current', {'packages':['timeline']});var container = document.getElementById('timeline-tooltip');var dataString;function addData(data) {dataString = data};google.charts.setOnLoadCallback(drawChart); function drawChart() {var dataTable = new google.visualization.DataTable({cols: [{id: 'eventType', label: 'Event Type', type: 'string'},{id: 'instance', type: 'string'},{type: 'string', role: 'tooltip', p:{html:true}},{id: 'start', label: 'Event Start Time', type: 'datetime'},{id: 'end', label: 'Event End Time', type: 'datetime'}],rows: dataString});var options = {'title':'Telemetry Log Data','width':1024,'height':400,'timeline': { groupByRowLabel: true },tooltip: {isHtml: true}};var chart = new google.visualization.Timeline(document.getElementById('chart_div'));google.visualization.events.addListener(chart, 'ready', afterDraw);chart.draw(dataTable, options);}function afterDraw() {}</script></head><body><div id=\"timeline-tooltip\" style=\"height: 180px;\"></div><div id='chart_div'></div></body></html>";

@implementation MMEConstants

@end

