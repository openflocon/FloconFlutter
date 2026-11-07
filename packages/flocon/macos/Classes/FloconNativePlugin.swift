import Cocoa
import FlutterMacOS

/// Reads the app icon and encodes it as a base64 PNG, 300 pixels wide.
public class FloconNativePlugin: NSObject, FlutterPlugin {
    private static let side = 300

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "io.github.openflocon/flocon", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(FloconNativePlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAppIcon":
            result(FloconNativePlugin.appIconBase64())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func appIconBase64() -> String? {
        let image = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])?.base64EncodedString()
    }
}
