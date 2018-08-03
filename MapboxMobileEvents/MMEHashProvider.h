#import <Foundation/Foundation.h>
#import "MMEEventsConfiguration.h"

@interface MMEHashProvider : NSObject

@property (nonatomic) NSArray *cnHashes;
@property (nonatomic) NSArray *comHashes;

- (void)updateHashesWithConfiguration:(MMEEventsConfiguration *)configuration;

@end
