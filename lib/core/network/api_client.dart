/*
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
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

    /// 🔓 SSL BYPASS (DEBUG ONLY)
    if (kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          log("➡️ REQUEST: ${options.method} ${options.uri}");

          // Agar request public nahi hai toh storage se token uthayein
          if (options.extra["isPublic"] != true) {
            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
              log("🔐 AUTH TOKEN ATTACHED FROM SECURE STORAGE");
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log("✅ RESPONSE [${response.statusCode}]");
          log("DATA: ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          log("❌ DIO ERROR: ${e.response?.statusCode} - ${e.message}");

          // 🔁 Prevent infinite refresh loop
          if (e.requestOptions.extra["isRetry"] == true) {
            return handler.next(e);
          }

          // 🔑 Handle Token Expiration (401)
          if (e.response?.statusCode == 401) {
            log("🔄 Token expired, attempting to refresh...");
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

  // ================== PUBLIC METHODS ==================

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

  // ================== PRIVATE HELPERS ==================

  Future<Response> _retry(RequestOptions requestOptions) async {
    // Retry karne se pehle naya token read kar lein (kyunki refresh ho chuka hai)
    final newToken = await _storage.read(key: 'access_token');
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (newToken != null) "Authorization": "Bearer $newToken",
      },
      extra: {...requestOptions.extra, "isRetry": true},
    );

    return _dio.request(
      requestOptions.uri.toString(),
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final refreshDio = Dio(BaseOptions(baseUrl: Endpoints.baseUrl));

      // SSL Bypass for Refresh Dio as well
      if (kDebugMode) {
        refreshDio.httpClientAdapter = _dio.httpClientAdapter;
      }

      final response = await refreshDio.post(
        "api/token/refresh/", // Ensure leading slash matches your backend
        data: {"refresh": refreshToken},
      );

      final newToken = response.data["access"];
      if (newToken != null) {
        await _storage.write(key: 'access_token', value: newToken);
        log("✅ Token refreshed and saved to Storage.");
        return true;
      }
      return false;
    } catch (e) {
      log("🔁 REFRESH TOKEN FAILED: $e");
      return false;
    }
  }
}*/

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