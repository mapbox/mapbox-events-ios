@import Foundation;
#import <sys/socket.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const MMEServiceFixtureErrorDomain;
extern NSTimeInterval const MME1sTimeout;
extern NSTimeInterval const MME10sTimeout;
extern NSTimeInterval const MME100sTimeout;
extern in_port_t const MMEFixtureDefaultPort;

typedef NS_ENUM(NSInteger, MMEServiceFixtureErrorNumber) { // 11000 - 11999
    MMEServiceFixtureNoError = 0,
    MMEServiceFixtureSocketCreateError = 11001,
    MMEServiceFixtureSocketOptionsError = 11002,
    MMEServiceFixtureSocketBindError = 11003
};

@interface MMEServiceFixture : NSObject
@property(class,nonatomic,assign) in_port_t servicePort;
@property(class,nonatomic,readonly) NSURL *serviceURL;

+ (MMEServiceFixture *)serviceFixtureWithFile:(NSString *)fixtureFile;
+ (MMEServiceFixture *)serviceFixtureWithResource:(NSString *)fixtureName;

// MARK: -

/// Waits for a connection to complete,
- (BOOL)waitForConnectionWithTimeout:(NSTimeInterval)timeout error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
