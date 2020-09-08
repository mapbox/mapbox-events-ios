import XCTest
import MapboxMobileEvents

class StartupTests: XCTestCase {

    func testInitPerformance() {
        self.measure(metrics: [XCTCPUMetric.init()]) {
            MMEEventsManager.shared().initialize(withAccessToken: "foo", userAgentBase: "bar", hostSDKVersion: "1.0.0")
        }
    }
}
