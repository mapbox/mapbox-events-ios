#import <UIKit/UIKit.h>

//! Project version number for MapboxMobileEvents.
FOUNDATION_EXPORT double MapboxMobileEventsVersionNumber;

//! Project version string for MapboxMobileEvents
FOUNDATION_EXPORT const unsigned char MapboxMobileEventsVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MapboxMobileEvents/PublicHeader.h>
#if SWIFT_PACKAGE
#import "../MMEConstants.h"
#import "../MMEEvent.h"
#import "../MMETypes.h"
#import "../MMEEventsManager.h"
#import "../NSUserDefaults+MMEConfiguration.h"
#else
#import <MapboxMobileEvents/MMEConstants.h>
#import <MapboxMobileEvents/MMEEvent.h>
#import <MapboxMobileEvents/MMETypes.h>
#import <MapboxMobileEvents/MMEEventsManager.h>
#import <MapboxMobileEvents/NSUserDefaults+MMEConfiguration.h>
#endif
