#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: -

@protocol MMEUIApplicationWrapper <NSObject>

/*! Integer Representation of content size scale (for  metrics) */
@property (nonatomic, readonly) NSInteger mme_contentSizeScale;

/*! The runtime state of the app. */
@property(nonatomic, readonly) UIApplicationState applicationState;

/*!
 @Brief Mark the start of a task that should continue if the app enters the background.
 @param handler A handler to be called shortly before the app’s remaining background time reaches 0. Use this handler to clean up and mark
 the end of the background task. Failure to end the task explicitly will result in the termination of the app. The system calls the handler
 synchronously on the main thread, blocking the app’s suspension momentarily.
 @returns A unique identifier for the new background task. You must pass this value to the endBackgroundTask: method to mark the end of this task.
 This method returns UIBackgroundTaskInvalid if running in the background is not possible.
 */
- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^ __nullable)(void))handler;

/*!
 @Brief Marks the end of a specific long-running background task.
 @param identifier An identifier returned by the beginBackgroundTaskWithExpirationHandler: method.
 */
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@end

@interface UIApplication (MMEUIApplicationWrapperConformance) <MMEUIApplicationWrapper>
@end

// MARK: - UIApplication Support

@interface MMEUIApplicationWrapper : NSObject <MMEUIApplicationWrapper>

/*! Default initializer which assumes UIApplication shared */
-(instancetype)init;

/*! Designated initializer */
-(instancetype)initWithApplication:(id <MMEUIApplicationWrapper>)application NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
