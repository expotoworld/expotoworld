import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Get the Google Maps API Key from the Info.plist
    guard let googleMapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String else {
      fatalError("Google Maps API Key not found in Info.plist. Make sure it's set in Info.plist and included via Secrets.xcconfig.")
    }

    // Check if the key is empty or a placeholder
    if googleMapsAPIKey.isEmpty || googleMapsAPIKey == "YOUR_KEY_HERE" {
        fatalError("Google Maps API Key is not configured. Please add it to ios/Flutter/Secrets.xcconfig")
    }

    // Provide the API key to Google Maps Services
    GMSServices.provideAPIKey(googleMapsAPIKey)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
