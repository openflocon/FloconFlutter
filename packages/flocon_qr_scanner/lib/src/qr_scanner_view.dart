import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qr_connector.dart';

/// Scans a QR code with the camera and connects the app to the desktop it holds the address of with
/// [Flocon.connect], so nobody has to type the IP.
///
/// [onResult] gets the result of each attempt; after a failure the view keeps scanning, so the user can try again.
/// The app must declare the camera usage (`NSCameraUsageDescription` on iOS and macOS, the `CAMERA` permission on
/// Android, `com.apple.security.device.camera` in the macOS entitlements). The view asks for the permission the
/// first time it is shown, and shows a message instead of the camera when it is denied or when there is no camera
/// (use [Flocon.connect] there).
class FloconQrScannerView extends StatefulWidget {
  const FloconQrScannerView({super.key, required this.onResult, this.connector});

  final void Function(FloconConnectResult result) onResult;

  /// Replaces the connection to [Flocon.connect], for tests.
  final FloconQrConnector? connector;

  @override
  State<FloconQrScannerView> createState() => _FloconQrScannerViewState();
}

class _FloconQrScannerViewState extends State<FloconQrScannerView> {
  late final FloconQrConnector _connector = widget.connector ?? FloconQrConnector();
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  Future<void> _onDetect(BarcodeCapture capture) async {
    for (final barcode in capture.barcodes) {
      final result = await _connector.handle(barcode.rawValue);
      if (result != null) {
        if (mounted) widget.onResult(result);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _Message(
            'The camera is not available (${error.errorCode.name}).\nUse Flocon.connect(address) to type the address instead.',
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Scan the QR code of Flocon Desktop',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]);
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
}
