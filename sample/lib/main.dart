import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Android emulator reaches the host machine through 10.0.2.2.
  // On a physical device, use the local IP of the computer running Flocon.
  Flocon.initialize(
    config: FloconConfig(host: Platform.isAndroid ? '10.0.2.2' : 'localhost'),
  );
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flocon Sample',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomeScreen(),
      );
}
