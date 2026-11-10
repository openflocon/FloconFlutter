import 'package:flocon/flocon.dart';
import 'package:flocon_qr_scanner/flocon_qr_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();
  runApp(MaterialApp(
    home: Scaffold(
      body: FloconQrScannerView(
        onResult: (result) => debugPrint('Flocon: $result'),
      ),
    ),
  ));
}
