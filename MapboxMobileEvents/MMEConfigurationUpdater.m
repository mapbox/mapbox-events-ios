#import "MMEConfigurationUpdater.h"
#import "MMEAPIClient.h"

@interface MMEConfigurationUpdater ()

@property (nonatomic) NSDate *configurationRotationDate;
@property (nonatomic) MMEEventsConfiguration *configuration;

@end

@implementation MMEConfigurationUpdater

- (instancetype)init {
    NSAssert(false, @"Use `-[MMEConfigurationUpdater initWithTimeInterval:]` to create instances of this class.");
    return nil;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        _timeInterval = timeInterval;
    }
    return self;
}

- (void)updateConfigurationFromAPIClient:(MMEAPIClient *)apiClient {
    if (self.configurationRotationDate && [[NSDate date] timeIntervalSinceDate:self.configurationRotationDate] >= 0) {
        self.configuration = nil;
    }
    if (!self.configuration) {
        [apiClient getConfigurationWithCompletionHandler:^(NSError * _Nullable error, NSData * _Nullable data) {
            if (!error) {
                self.configuration = [MMEEventsConfiguration configuration];
                [self parseJSONFromData:data];
                
                [self.delegate configurationDidUpdate:self.configuration];
                self.configurationRotationDate = [[NSDate date] dateByAddingTimeInterval:self.timeInterval];
            }
        }];
    }
}

#pragma mark - Utilities

- (void)parseJSONFromData:(NSData *)data {
    if (!data) {
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    
    if (!jsonError) {
        NSArray *blacklist = [json objectForKey:@"RevokedCertKeys"];
        self.configuration.blacklist = blacklist;
    }
}


@end
