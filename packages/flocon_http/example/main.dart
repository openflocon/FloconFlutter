import 'package:flocon/flocon.dart';
import 'package:flocon_http/flocon_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();

  final client = FloconHttpClient(http.Client());
  await client.get(Uri.parse('https://httpbin.org/get'));
  client.close();
}
