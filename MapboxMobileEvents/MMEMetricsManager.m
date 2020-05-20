#import "MMEMetricsManager.h"
#import "MMEReachability.h"
#import "MMEConstants.h"
#import "MMEDate.h"
#import "NSProcessInfo+SystemInfo.h"
#import "MMEEventConfigProviding.h"
#import "MMEEvent.h"
#import "MMELogger.h"

// MARK: -

@interface MMEMetricsManager ()

@property (nonatomic, strong) MMEMetrics *metrics;
@property (nonatomic, strong) id <MMEEventConfigProviding> config;
@property (nonatomic, copy) NSURL *pendingMetricsFileURL;
@property (nonatomic, copy) OnMetricsError onMetricsError;
@property (nonatomic, copy) OnMetricsException onMetricsException;
@property (nonatomic, copy) IsReachableViaWifi isReachableViaWifi;
@end

// MARK: -

@implementation MMEMetricsManager

// MARK: - Initializers

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
         pendingMetricsFileURL:(NSURL*)pendingMetricsFileURL {


    return [self initWithConfig:config
          pendingMetricsFileURL:pendingMetricsFileURL
                 onMetricsError:^(NSError * _Nonnull error) {}
             onMetricsException:^(NSException * _Nonnull exception) {}
             isReachableViaWifi:^BOOL{
        return [[MMEReachability reachabilityForLocalWiFi] isReachableViaWiFi];
    }];
}

- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config
         pendingMetricsFileURL:(NSURL*)pendingMetricsFileURL
                onMetricsError:(OnMetricsError)onMetricsError
            onMetricsException:(OnMetricsException)onMetricsException
            isReachableViaWifi:(IsReachableViaWifi)isReachableViaWifi {

    if ((self = super.init)) {

        self.config = config;
        self.pendingMetricsFileURL = pendingMetricsFileURL;

        self.onMetricsError = onMetricsError;
        self.onMetricsException = onMetricsException;
        self.isReachableViaWifi = isReachableViaWifi;

        [self resetMetrics];
    }

    return self;
}

// MARK: - File Methods

/// Deletes Pending Metrics Event File (stashed metrics which were not sent)
- (BOOL)deletePendingMetricsEventFile {
    BOOL success = NO;

    if ([NSFileManager.defaultManager fileExistsAtPath: self.pendingMetricsFileURL.path]) {
        NSError *fileError = nil;

        if (![NSFileManager.defaultManager removeItemAtURL:self.pendingMetricsFileURL
                                                     error:&fileError]) {

            self.onMetricsError(fileError);
        }
        else {  // we successfully removed the file
            success = YES;
        }
    }
    else { // there was no file to begin with
        success = YES;
    }

    return success;
}

/*!
 @Brief Creates Metrics Event Directory
 @Returns Success Status of Directory Creation
 */
- (BOOL)createFrameworkMetricsEventDirectory {

    NSURL* mmeDirectory = [self.pendingMetricsFileURL URLByDeletingLastPathComponent];
    BOOL urlIsDirectory = YES;

    // Check if item exists?
    BOOL sdkPathExtant = [NSFileManager.defaultManager fileExistsAtPath:mmeDirectory.path
                                                            isDirectory:&urlIsDirectory];
    NSError* sdkPathError = nil;

    // If not a directory (it would prevent us from writing), remove it
    if (!urlIsDirectory) {

        if ([NSFileManager.defaultManager removeItemAtURL:mmeDirectory error:&sdkPathError]) {
            sdkPathExtant = NO;
        }
        else {
            self.onMetricsError(sdkPathError);
        }
    }

    // If directly doesn't exist, create it
    if (!sdkPathExtant) {
        if ( [NSFileManager.defaultManager createDirectoryAtURL:mmeDirectory
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&sdkPathError]) {

            // Exclude from backup
            if ([mmeDirectory setResourceValue:@(YES)
                                        forKey:NSURLIsExcludedFromBackupKey
                                         error:&sdkPathError]) {
                urlIsDirectory = YES;
            }
            else {
                self.onMetricsError(sdkPathError);
            }
        }
        else {
            self.onMetricsError(sdkPathError);
        }
    }

    return urlIsDirectory;
}

// MARK: - Update Methods

- (void)updateMetricsFromEventQueue:(NSArray *)eventQueue {
    if (eventQueue.count > 0) {
        self.metrics.eventCountTotal += (int)eventQueue.count;
        
        for (MMEEvent *event in eventQueue) {
            NSNumber *eventCount = [self.metrics.eventCountPerType objectForKey:event.name];
            eventCount = [NSNumber numberWithInteger:[eventCount integerValue] + 1];
            [self.metrics.eventCountPerType setObject:eventCount forKey:event.name];
        }
    }
}

- (void)updateMetricsFromEventCount:(NSUInteger)eventCount
                            request:(nullable NSURLRequest *)request
                              error:(nullable NSError *)error {
    if (request.HTTPBody) {
        [self updateSentBytes:request.HTTPBody.length];
    }
    
    if (request == nil && error == nil) {
        [self updateEventsFailedCount:eventCount];
    } else if (error == nil) {
        //successful request -- the events for this are counted elsewhere
        self.metrics.requests++;
    } else {
        [self updateEventsFailedCount:eventCount];

        NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:MMEResponseKey];
        NSString *urlString = response.URL.absoluteString;
        NSNumber *statusCode = @(response.statusCode);
        NSString *statusCodeKey = [statusCode stringValue];
        
        if (urlString && [self.metrics.failedRequestsDict objectForKey:MMEEventKeyHeader] == nil) {
            [self.metrics.failedRequestsDict setObject:urlString forKey:MMEEventKeyHeader];
        }
    
        if ([self.metrics.failedRequestsDict objectForKey:MMEEventKeyFailedRequests] == nil) {
            [self.metrics.failedRequestsDict setObject:[NSMutableDictionary new] forKey:MMEEventKeyFailedRequests];
        }
        
        NSMutableDictionary *failedRequests = [self.metrics.failedRequestsDict objectForKey:MMEEventKeyFailedRequests];
        
        NSNumber *failedCount = [failedRequests objectForKey:statusCodeKey];
        failedCount = [NSNumber numberWithInteger:[failedCount integerValue] + 1];
        [failedRequests setObject:failedCount forKey:statusCodeKey];
        
        [self.metrics.failedRequestsDict setObject:failedRequests forKey:MMEEventKeyFailedRequests];
    }
}

- (void)updateEventsFailedCount:(NSUInteger)eventCount {
    self.metrics.eventCountFailed += eventCount;
}

- (void)updateSentBytes:(NSUInteger)bytes {
    if (self.isReachableViaWifi()) {
        self.metrics.wifiBytesSent += bytes;
    } else {
        self.metrics.cellBytesSent += bytes;
    }
}

- (void)updateReceivedBytes:(NSUInteger)bytes {
    if (self.isReachableViaWifi()) {
        self.metrics.wifiBytesReceived += bytes;
    } else {
        self.metrics.cellBytesReceived += bytes;
    }
}

- (void)incrementAppWakeUpCount {
    self.metrics.appWakeups++;
}

- (void)updateConfigurationJSON:(NSDictionary *)configuration {
    if (configuration) {
        self.metrics.configResponseDict = configuration;
    }
}

- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate {
    if (!self.metrics.deviceLat && !self.metrics.deviceLon) {
        self.metrics.deviceLat = round(coordinate.latitude*1000)/1000;
        self.metrics.deviceLon = round(coordinate.longitude*1000)/1000;
    }
}

- (void)resetMetrics {
    self.metrics = [MMEMetrics new];
}

// Does Metrics Events not use MMEEventKeyEvent?
- (NSDictionary *)attributes {
    MMEMutableMapboxEventAttributes *attributes = [MMEMutableMapboxEventAttributes dictionary];
    attributes[MMEEventKeyFailedRequests] = [self jsonStringfromDict:self.metrics.failedRequestsDict];
    attributes[MMEEventEventCountPerType] = [self jsonStringfromDict:self.metrics.eventCountPerType];
    attributes[MMEEventConfigResponse] = [self jsonStringfromDict:self.metrics.configResponseDict];
    attributes[MMEEventTotalDataSent] = @(self.metrics.totalBytesSent);
    attributes[MMEEventCellDataSent] = @(self.metrics.cellBytesSent);
    attributes[MMEEventWiFiDataSent] = @(self.metrics.wifiBytesSent);
    attributes[MMEEventTotalDataReceived] = @(self.metrics.totalBytesReceived);
    attributes[MMEEventCellDataReceived] = @(self.metrics.cellBytesReceived);
    attributes[MMEEventWiFiDataReceived] = @(self.metrics.wifiBytesReceived);
    attributes[MMEEventEventCountFailed] = @(self.metrics.eventCountFailed);
    attributes[MMEEventEventCountTotal] = @(self.metrics.eventCountTotal);
    attributes[MMEEventEventCountMax] = @(self.metrics.eventCountMax);
    attributes[MMEEventAppWakeups] = @(self.metrics.appWakeups);
    attributes[MMEEventRequests] = @(self.metrics.requests);
    attributes[MMEEventDeviceTimeDrift] = @(MMEDate.recordedTimeOffsetFromServer);
    attributes[MMEEventKeyModel] = NSProcessInfo.mme_hardwareModel;
    attributes[MMEEventKeyPlatform] = NSProcessInfo.mme_platformName;
    attributes[MMEEventKeyOperatingSystem] = NSProcessInfo.mme_osVersion;
    attributes[MMEEventKeyDevice] = NSProcessInfo.mme_deviceModel;
    attributes[MMEEventSDKIdentifier] = self.config.legacyUserAgentBase;
    attributes[MMEEventSDKVersion] = self.config.legacyHostSDKVersion;
    attributes[MMEEventKeyUserAgent] = self.config.userAgentString;

    if (self.metrics.deviceLat != 0 && self.metrics.deviceLon != 0) { // check for null-island
        attributes[MMEEventDeviceLat] = @(self.metrics.deviceLat);
        attributes[MMEEventDeviceLon] = @(self.metrics.deviceLon);
    }

    if (self.metrics.recordingStarted) {
        attributes[MMEEventDateUTC] = [MMEDate.iso8601DateOnlyFormatter stringFromDate:self.metrics.recordingStarted];
    }

    return attributes;
}

- (nullable MMEEvent *)loadPendingTelemetryMetricsEvent {
    MMEEvent* pending = nil;

    if ([NSFileManager.defaultManager fileExistsAtPath:self.pendingMetricsFileURL.path]) {
        @try {
            NSData *thenData = [NSData dataWithContentsOfURL:self.pendingMetricsFileURL];
            NSKeyedUnarchiver* unarchiver = [NSKeyedUnarchiver.alloc initForReadingWithData:thenData];
            unarchiver.requiresSecureCoding = YES;
            pending = [unarchiver decodeObjectOfClass:MMEEvent.class forKey:NSKeyedArchiveRootObjectKey];
        }
        @catch (NSException *exception) {
            self.onMetricsException(exception);
        }
    }
    //decoding failed; deleting metrics event
    if (pending == nil) {
        [self deletePendingMetricsEventFile];
    }
    return pending;
}

- (nullable MMEEvent *)generateTelemetryMetricsEvent {
    NSDate *zeroHour = [self.metrics.recordingStarted mme_startOfTomorrow];
    NSString *metricsDate = [MMEDate.iso8601DateFormatter stringFromDate:NSDate.date];
    MMEEvent *telemetryMetrics = [MMEEvent telemetryMetricsEventWithDateString:metricsDate attributes:self.attributes];

    if (zeroHour.timeIntervalSinceNow > 0) { // it's not time to send metrics yet
        if (@available(iOS 10.0, macos 10.12, tvOS 10.0, watchOS 3.0, *)) { // write them to a pending file
            [self deletePendingMetricsEventFile];

            if ([self createFrameworkMetricsEventDirectory]) {
                @try { // to write the metrics event to the pending metrics event path
                    NSKeyedArchiver *archiver = [NSKeyedArchiver new];
                    archiver.requiresSecureCoding = YES;
                    [archiver encodeObject:telemetryMetrics forKey:NSKeyedArchiveRootObjectKey];


                    if (![archiver.encodedData writeToURL:self.pendingMetricsFileURL atomically:YES]) {
                        MMELog(MMELogInfo, MMEDebugEventTypeTelemetryMetrics, ([NSString stringWithFormat:@"Failed to archiveRootObject: %@ toFile: %@",
                                                                                telemetryMetrics, self.pendingMetricsFileURL.absoluteString]));
                    }
                }
                @catch (NSException* exception) {
                    self.onMetricsException(exception);
                }
            }
        }
        return nil;
    }
    [self deletePendingMetricsEventFile];
    
    return telemetryMetrics;
}

// MARK: -

- (NSString *)jsonStringfromDict:(NSDictionary *)dictionary {
    //prevents empty dictionaries from being stringified
    if ([dictionary count] > 0) {
        NSString *jsonString;
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&jsonError];

        if (jsonData) {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else if (jsonError) {
            self.onMetricsError(jsonError);
        }
        return jsonString;
    }
    return nil;
}

@end
