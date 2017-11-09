#import "MMECategoryLoader.h"

#import "CLLocation+MMEMobileEvents.h"
#import "NSData+MMEGZIP.h"

@implementation MMECategoryLoader

//forces the classes called by these methods to be included in the binary.
//used to prevent crashes and simplify installation for developers of the library.
+ (void)loadCategories {
    mme_linkCLLocationCategory();
    mme_linkNSDataCategory();
}

@end
