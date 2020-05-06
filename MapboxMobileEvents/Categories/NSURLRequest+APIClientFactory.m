#import "NSURLRequest+APIClientFactory.h"
#import "NSUserDefaults+MMEConfiguration.h"
#import "MMEConstants.h"

@implementation NSURLRequest (APIClientFactory)

+ (NSURLRequest *)configurationRequest {

    NSString *path = [NSString stringWithFormat:@"%@?access_token=%@", MMEAPIClientEventsConfigPath, NSUserDefaults.mme_configuration.mme_accessToken];
    NSURL *configServiceURL = [NSURL URLWithString:path relativeToURL:NSUserDefaults.mme_configuration.mme_configServiceURL];
    NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:configServiceURL];

    [request setValue:NSUserDefaults.mme_configuration.mme_userAgentString forHTTPHeaderField:MMEAPIClientHeaderFieldUserAgentKey];
    [request setValue:MMEAPIClientHeaderFieldContentTypeValue forHTTPHeaderField:MMEAPIClientHeaderFieldContentTypeKey];
    [request setHTTPMethod:MMEAPIClientHTTPMethodPost];

    return request;
}
@end
