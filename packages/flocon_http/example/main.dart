import 'package:flocon/flocon.dart';
import 'package:flocon_http/flocon_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // the network options apply to every client
    await startFlocon((flocon) => flocon
      ..install(FloconNetwork(shouldLog: (request) => request.url.host != 'analytics.example.com')));
  }
  final client = http.Client().withFlocon();
  await client.get(Uri.parse('https://httpbin.org/get'));
  client.close();
}
