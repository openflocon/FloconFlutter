import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';
import 'package:flocon_files/flocon_files.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android emulator reaches the host machine through 10.0.2.2.
  // On a physical device, use the local IP of the computer running Flocon.
  Flocon.initialize(
    config: FloconConfig(host: Platform.isAndroid ? '10.0.2.2' : 'localhost'),
  );
  await floconEnableFilesPlugin(); // browse and download the files of the app
  await floconEnableCrashReporter(); // uncaught errors are reported to Flocon
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
