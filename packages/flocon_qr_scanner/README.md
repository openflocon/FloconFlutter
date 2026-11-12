# flocon_qr_scanner

Connects your app to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger by scanning the QR code it shows (Android, iOS, macOS), so nobody has to type the IP address.

## Installation

```bash
flutter pub add flocon flocon_qr_scanner
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^2.0.0
  flocon_qr_scanner: ^2.0.0
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

See the [documentation](https://openflocon.github.io/Flocon/setup/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
