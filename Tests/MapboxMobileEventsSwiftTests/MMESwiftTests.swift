import Foundation
import XCTest
import MapboxMobileEvents


class MMESwiftTests: XCTestCase {

    func testSwiftBridge() {
        MMEEventsManager.shared().enqueueEvent(withName: "test")
    }
}
