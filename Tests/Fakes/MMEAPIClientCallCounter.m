#import "MMEAPIClientCallCounter.h"

@interface MMEAPIClientCallCounter ()
@property (nonatomic, assign) NSUInteger postEventsCount;
@property (nonatomic, assign) NSUInteger getConfigurationCount;
@property (nonatomic, assign) NSUInteger postMetadataCount;
@property (nonatomic, assign) NSUInteger performRequestCount;
@end

@implementation MMEAPIClientCallCounter

- (instancetype)initWithConfig:(id<MMEEventConfigProviding>)config
{
    self = [super initWithConfig:config];
    if (self) {
        self.postEventsCount = 0;
        self.getConfigurationCount = 0;
        self.postMetadataCount = 0;
        self.performRequestCount = 0;
    }
    return self;
}

- (void)postEvents:(NSArray<MMEEvent *> *)events completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    self.postEventsCount += 1;
    [super postEvents:events completionHandler:completionHandler];
}

- (void)getEventConfigWithCompletionHandler:(nullable void (^)(MMEConfig* _Nullable config, NSError * _Nullable error))completion {
    self.getConfigurationCount += 1;
    [super getEventConfigWithCompletionHandler:completion];
}

- (void)postMetadata:(NSArray *)metadata filePaths:(NSArray *)filePaths completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    self.postMetadataCount += 1;
    [super postMetadata:metadata filePaths:filePaths completionHandler:completionHandler];
}

- (void)performRequest:(NSURLRequest *)request completion:(void (^)(NSData * _Nullable, NSHTTPURLResponse * _Nullable, NSError * _Nullable))completion {
    self.performRequestCount += 1;
    [super performRequest:request completion:completion];
}

@end
