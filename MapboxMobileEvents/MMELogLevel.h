/*! Log Levels for Runtime Filtering */
typedef NS_ENUM(NSUInteger, MMELogLevel) {
    /// Log level for no messages
    MMELogNone = 0,

    /// Fatal Error Messages
    MMELogFatal,

    /// Error Messages
    MMELogError,

    /// Warning Messages
    MMELogWarn,

    /// Informational Messages
    MMELogInfo,

    /// Event Lifecycle Messages
    MMELogEvent,

    /// Network Connection Messages
    MMELogNetwork,

    /// All Debug Messages
    MMELogDebug
};
