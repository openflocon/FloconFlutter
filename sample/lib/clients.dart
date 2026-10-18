import 'package:dio/dio.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flocon_http/flocon_http.dart';
import 'package:http/http.dart' as http;

const jsonPlaceholder = 'https://jsonplaceholder.typicode.com';

/// Dio client, every call is sent to Flocon by the interceptor.
final dio = Dio(BaseOptions(baseUrl: jsonPlaceholder))..interceptors.add(FloconDioInterceptor());

/// package:http client, every call is sent to Flocon by the wrapper.
final httpClient = FloconHttpClient(http.Client());
