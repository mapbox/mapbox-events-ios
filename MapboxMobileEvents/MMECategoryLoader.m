#import "MMECategoryLoader.h"

#import "CLLocation+MMEMobileEvents.h"
#import "NSData+MMEGZIP.h"

@implementation MMECategoryLoader

+ (void)loadCategories {
    mme_linkCLLocationCategory();
    mme_linkNSDataCategory();
}

@end
