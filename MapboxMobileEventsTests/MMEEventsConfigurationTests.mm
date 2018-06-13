#import <Cedar/Cedar.h>
#import "MMEEventsConfiguration.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEEventsConfigurationSpec)

describe(@"MMEEventsConfiguration", ^{

    __block MMEEventsConfiguration *configuration;

    describe(@"creating an instance", ^{

        // This block runs after each nested context that also contains an 'it' block
        subjectAction(^{ configuration = [MMEEventsConfiguration configuration]; });

        describe(@"with a default configuration", ^{

            // subjectAction runs here

            it(@"uses the standard geofence", ^{
                configuration.locationManagerHibernationRadius should be_close_to(300);
            });
        });

        describe(@"with a custom configuration", ^{
            NSBundle *bundle = [NSBundle mainBundle];

            beforeEach(^{
                spy_on(bundle);
            });

            afterEach(^{
                stop_spying_on(bundle);
            });

            context(@"without a specific geofence radius", ^{
                beforeEach(^{
                    NSDictionary *infoDictionary = @{ @"MMEEventsProfile" : @"Custom" };
                    bundle stub_method(@selector(infoDictionary)).and_return(infoDictionary);
                });

                // subjectAction runs here

                it(@"uses an alternate geofence radius of 1200", ^{
                    configuration.locationManagerHibernationRadius should be_close_to(1200);
                });
            });

            context(@"with a specific geofence radius set", ^{
                beforeEach(^{
                    NSDictionary *infoDictionary = @{ @"MMEEventsProfile" : @"Custom",
                                                      @"MMECustomGeofenceRadius" : @1000 };
                    bundle stub_method(@selector(infoDictionary)).and_return(infoDictionary);
                });

                // subjectAction runs here

                it(@"uses the specified alternate geofence radius", ^{
                    configuration.locationManagerHibernationRadius should be_close_to(1000);
                });

            });
        });
    });
});

SPEC_END
