#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MMEErrorCode) {
    MMESessionFailedError,
    MMEUnexpectedResponseError
};

@interface NSError (APIClient)

- (nullable instancetype)initWith:(NSURLRequest *)request
                     httpResponse:(nullable NSHTTPURLResponse *)response
                            error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
