#import "NSError+APIClient.h"
#import "MMEConstants.h"

@implementation NSError (APIClient)

- (nullable instancetype)initWith:(NSURLRequest *)request
                     httpResponse:(nullable NSHTTPURLResponse *)response
                            error:(nullable NSError *)error {

    if (response.statusCode >= 400) { // all 4xx and 5xx errors should be reported
        NSString *description = [NSString stringWithFormat:@"The session data task failed. Original request was: %@",
                                 request ?: [NSNull null]];
        NSString *reason = [NSString stringWithFormat:@"The status code was %ld", (long)response.statusCode];
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:reason forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setValue:response forKey:MMEResponseKey];
        if (error) { // record the session error as the underlying error
            [userInfo setValue:error forKey:NSUnderlyingErrorKey];
        }

        return [self initWithDomain:MMEErrorDomain code:MMESessionFailedError userInfo:userInfo];
    } else {
        return nil;
    }

}

@end
