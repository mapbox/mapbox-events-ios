#import <Cedar/Cedar.h>
#import "MMEEventsService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MMEEventsServiceSpec)

describe(@"MMEEventsService", ^{

    __block MMEEventsService *eventsService;

    describe(@"creating an instance", ^{

        // This block runs after each nested context that also contains an 'it' block
        subjectAction(^{ eventsService = [[MMEEventsService alloc] init]; });

        describe(@"with a default configuration", ^{

            // subjectAction runs here

            it(@"uses the standard geofence", ^{
                eventsService.configuration.locationManagerHibernationRadius should be_close_to(300);
            });
        });

        describe(@"with a custom configuration", ^{
            NSBundle *bundle = [NSBundle mainBundle];

            beforeEach(^{
                spy_on(bundle);

                bundle stub_method(@selector(objectForInfoDictionaryKey:)).with(@"MMEEventsProfile").and_return(@"Custom");
            });

            afterEach(^{
                stop_spying_on(bundle);
            });

            context(@"without a specific geofence radius", ^{

                // subjectAction runs here

                it(@"uses an alternate geofence radius of 1200", ^{
                    eventsService.configuration.locationManagerHibernationRadius should be_close_to(1200);
                });
            });

            context(@"with a specific geofence radius set", ^{
                beforeEach(^{
                    bundle stub_method(@selector(objectForInfoDictionaryKey:)).with(@"MMECustomGeofenceRadius").and_return(@1000);
                });

                // subjectAction runs here

                it(@"uses the specified alternate geofence radius", ^{
                    eventsService.configuration.locationManagerHibernationRadius should be_close_to(1000);
                });

            });
        });
    });
});

SPEC_END
