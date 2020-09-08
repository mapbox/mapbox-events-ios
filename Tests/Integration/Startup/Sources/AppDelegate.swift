import UIKit
import MapboxMobileEvents
import os.log
import os.signpost


struct SignpostLog {
    static var initTime = OSLog(subsystem: "com.mapbox.MME", category: "INIT")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MMEEventsManagerDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        self.window = UIWindow(frame: UIScreen.main.bounds)

        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()

        os_signpost(.begin, log: SignpostLog.initTime, name: "INIT")
        MMEEventsManager.shared().initialize(withAccessToken: "foo", userAgentBase: "bar", hostSDKVersion: "1.0.0")
        os_signpost(.end, log: SignpostLog.initTime, name: "INIT")

        return true
    }
}
