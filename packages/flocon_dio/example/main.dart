import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize();

  // Add it last, so it sees the final request and the raw response.
  final dio = Dio()..interceptors.add(FloconDioInterceptor());
  await dio.get<Object?>('https://httpbin.org/get');
}
