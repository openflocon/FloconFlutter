# flocon_qr_scanner

Connects your app to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger by scanning the QR code it shows (Android, iOS, macOS), so nobody has to type the IP address.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_qr_scanner:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_qr_scanner
```

## Usage

```dart
import 'package:flocon_qr_scanner/flocon_qr_scanner.dart';

FloconQrScannerView(onResult: (result) {
  if (result is FloconConnectResultConnected) Navigator.pop(context);
})
```

Declare the camera usage: `NSCameraUsageDescription` (iOS, macOS), the `CAMERA` permission (Android),
`com.apple.security.device.camera` in the macOS entitlements. `mobile_scanner` needs `minSdk` 23 on Android.

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
