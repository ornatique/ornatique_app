import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      NotificationCenter.default.addObserver(
          forName: UIApplication.userDidTakeScreenshotNotification,
          object: nil,
          queue: .main
      ) { notification in
          print("⚠️ Screenshot taken!")

          // Show black overlay
          if let window = UIApplication.shared.windows.first {
              let blackView = UIView(frame: window.bounds)
              blackView.backgroundColor = .black
              blackView.tag = 9999 // So we can remove it later
              window.addSubview(blackView)
              window.bringSubviewToFront(blackView)
              
              // Remove after short delay (optional)
              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                  window.viewWithTag(9999)?.removeFromSuperview()
              }
          }
      }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
