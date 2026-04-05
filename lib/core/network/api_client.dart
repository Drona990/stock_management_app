
import 'dart:developer';
import 'dart:io'; // Mobile/Desktop ke liye
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // IOHttpClientAdapter ke liye
import 'package:flutter/foundation.dart'; // kIsWeb aur kDebugMode ke liye
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constant/endpoints.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient(this._dio) {
    _dio.options = BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    /// 🔓 SSL BYPASS (MOBILE/DESKTOP ONLY)
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          if (kDebugMode) {
            // Development mein local/self-signed certificates allow karein
            client.badCertificateCallback = (cert, host, port) => true;
          }
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          log("➡️ REQUEST: ${options.method} ${options.uri}");
          if (options.extra["isPublic"] != true) {
            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log("✅ RESPONSE [${response.statusCode}]");
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          log("❌ DIO ERROR: ${e.response?.statusCode} - ${e.message}");

          if (e.response?.statusCode == 401 && e.requestOptions.extra["isRetry"] != true) {
            log("🔄 Attempting Token Refresh...");
            final refreshed = await _refreshToken();
            if (refreshed) {
              final response = await _retry(e.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ================== PUBLIC METHODS (ALL INCLUDED) ==================

  Future<Response> get(String path, {Map<String, dynamic>? query, bool isPublic = false}) {
    return _dio.get(path, queryParameters: query, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> post(String path, {dynamic data, bool isPublic = false}) {
    return _dio.post(path, data: data, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> put(String path, {dynamic data, bool isPublic = false}) {
    return _dio.put(path, data: data, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> patch(String path, {dynamic data, bool isPublic = false}) {
    return _dio.patch(path, data: data, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> delete(String path, {dynamic data, bool isPublic = false}) {
    return _dio.delete(path, data: data, options: Options(extra: {"isPublic": isPublic}));
  }

  // ================== HELPERS ==================

  Future<Response> _retry(RequestOptions requestOptions) async {
    final newToken = await _storage.read(key: 'access_token');
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          if (newToken != null) "Authorization": "Bearer $newToken",
        },
        extra: {...requestOptions.extra, "isRetry": true},
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      // Fresh instance for refresh to avoid interceptor conflict
      final response = await Dio().post(
        "${Endpoints.baseUrl}api/token/refresh/",
        data: {"refresh": refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: response.data["access"]);
        log("✅ Token Refreshed Successfully");
        return true;
      }
      return false;
    } catch (e) {
      log("🔁 Refresh Token Failed: $e");
      return false;
    }
  }
}