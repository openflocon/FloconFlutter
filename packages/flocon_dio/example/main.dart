import 'package:dio/dio.dart';
import 'package:flocon/flocon.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    // the network options apply to every client
    await startFlocon((flocon) => flocon
      ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'picsum.photos')));
  }
  // withFlocon() adds the Flocon interceptor: call it after adding your own interceptors.
  final dio = Dio().withFlocon();
  await dio.get<Object?>('https://httpbin.org/get');
}
