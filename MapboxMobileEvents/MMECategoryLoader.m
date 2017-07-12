#import "MMECategoryLoader.h"

#import "CLLocation+MMEMobileEvents.h"

@implementation MMECategoryLoader

+ (void)loadCategories {
    mme_linkCLLocationCategory();
}

@end
