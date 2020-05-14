#import <Foundation/Foundation.h>

@class MMEEventsConfiguration;
@protocol MMEEventConfigProviding;

NS_ASSUME_NONNULL_BEGIN

@interface MMECertPin : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(id <MMEEventConfigProviding>)config;

- (void)handleChallenge:(NSURLAuthenticationChallenge * _Nonnull)challenge
      completionHandler:(void (^ _Nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;

@end

NS_ASSUME_NONNULL_END
