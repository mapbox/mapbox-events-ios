#import <Foundation/Foundation.h>
#import "MMEEvent.h"

NS_ASSUME_NONNULL_BEGIN

/*! @Brief Provides a model to host for validation APIClient Block Calls. Modeled as arrays to validate call counts as well as contents */
@interface MMEAPIClientBlockCounter : NSObject

/*! @Brief Array of error events */
@property (nonatomic) NSMutableArray<NSError*>* onErrors;

/*! @Brief Array of onBytes Received */
@property (nonatomic) NSMutableArray<NSNumber*>* onBytesReceived;

/*! @Brief Array of on eventQueue change Events */
@property (nonatomic) NSMutableArray* eventQueue;

/*! @Brief Arrach of EventCount Change Events */
@property (nonatomic) NSMutableArray<NSNumber*>* eventCount;

/*! @Brief Array of onGenerateTelemetry Block Calls*/
@property (nonatomic) NSUInteger generateTelemetry;

/*! @Brief Arrach of Event Events */
@property (nonatomic) NSMutableArray<MMEEvent*>* logEvents;

@end

NS_ASSUME_NONNULL_END
