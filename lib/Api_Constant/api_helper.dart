import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'ApiConstants.dart';

class ApiHelper {
  static final ApiHelper _instance = ApiHelper._internal();
  late Dio _dio;

  factory ApiHelper() => _instance;

  ApiHelper._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'accept': 'application/json',
        },
      ),
    );

    /// 🔥 GLOBAL INTERCEPTOR
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final packageInfo = await PackageInfo.fromPlatform();

          /// ✅ Global headers
          options.headers.addAll({
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'app-version': packageInfo.version,
          });

          /// ✅ LOG
          print('➡️ INTERCEPTOR REQUEST');
          print('URL: ${options.uri}');
          print('HEADERS: ${options.headers}');
          print('QUERY: ${options.queryParameters}');
          print('BODY: ${options.data}');
          print('---------------------------');

          handler.next(options);
        },
        onResponse: (response, handler) {
          print('⬅️ RESPONSE ${response.statusCode}');
          print('DATA: ${response.data}');
          print('---------------------------');
          handler.next(response);
        },
        onError: (e, handler) {
          print('🚨 ERROR ${e.response?.statusCode}');
          print('DATA: ${e.response?.data}');
          print('---------------------------');
          handler.next(e);
        },
      ),
    );
  }

  // 🔹 GET REQUEST (HEADERS MERGED – SAFE)
  Future<Response?> getRequest(
      String endpoint, {
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      /// ✅ Extra headers (will MERGE)
      final extraHeaders = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app-version': packageInfo.version,
      };

      print('➡️ GET REQUEST (MANUAL)');
      print('URL: $endpoint');
      print('HEADERS: $extraHeaders');
      print('QUERY: $queryParams');
      print('---------------------------');

      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          headers: extraHeaders, // ✅ merged, not override
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (e) {
      print('❌ GET EXCEPTION: $e');
      return null;
    }
  }

  // 🔹 POST REQUEST
  Future<Response?> postRequest(String endpoint, dynamic data) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (e) {
      print('❌ POST EXCEPTION: $e');
      return null;
    }
  }
}
