import 'package:flocon/flocon.dart';
import 'package:flocon_qr_scanner/flocon_qr_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) await startFlocon((flocon) => flocon..install(const FloconNetwork()));
  runApp(MaterialApp(
    home: Scaffold(
      body: FloconQrScannerView(
        onResult: (result) => debugPrint('Flocon: $result'),
      ),
    ),
  ));
}
