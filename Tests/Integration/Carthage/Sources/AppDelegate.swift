import UIKit
import MapboxMobileEvents


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MMEEventsManagerDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        MMEEventsManager.shared().delegate = self
        assert(MMEEventsManager.shared().delegate != nil)

        return true
    }
}
