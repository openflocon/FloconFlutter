import Flutter
import UIKit

/// Reads the app icon and encodes it as a base64 PNG, at most 300 pixels wide.
public class FloconDevicePlugin: NSObject, FlutterPlugin {
    private static let maxSize: CGFloat = 300

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "io.github.openflocon/flocon_device", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(FloconDevicePlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAppIcon":
            result(FloconDevicePlugin.appIconBase64())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func appIconBase64() -> String? {
        guard let image = appIcon() else { return nil }
        // in pixels: a 60 points icon is 120 pixels at @2x
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let scale = min(maxSize / pixelWidth, maxSize / pixelHeight, 1)
        let size = CGSize(width: (pixelWidth * scale).rounded(), height: (pixelHeight * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.pngData()?.base64EncodedString()
    }

    /// iOS has no API that returns the app icon: its file names are listed under `CFBundleIcons`.
    private static func appIcon() -> UIImage? {
        let info = Bundle.main.infoDictionary
        let primary = (info?["CFBundleIcons"] as? [String: Any])?["CFBundlePrimaryIcon"] as? [String: Any]
        var names: [String] = []
        if let name = primary?["CFBundleIconName"] as? String { names.append(name) }
        names += (primary?["CFBundleIconFiles"] as? [String]) ?? []
        return names
            .compactMap { UIImage(named: $0) }
            .max { $0.size.width * $0.scale < $1.size.width * $1.scale }
    }
}
