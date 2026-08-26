
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 🌟 Added for UI overlays/SnackBars
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../utils/constant/endpoints.dart';
import '../utils/app_routes.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => Endpoints.baseUrl;

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

          // Dynamic tracking ke liye session_id pass karein aur request type trace karein
          final sessionId = await _storage.read(key: 'session_id');
          if (sessionId != null) {
            options.headers["X-Session-ID"] = sessionId;
          }
          options.headers["X-Device-Type"] = kIsWeb ? "Flutter-Web" : Platform.operatingSystem;

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

          if (e.response?.statusCode == 401) {
            // Case A: Agar yeh simple background retry nahi hai, toh refresh attempt karein
            if (e.requestOptions.extra["isRetry"] != true) {
              log("🔄 Attempting Token Refresh...");
              final refreshed = await _refreshToken();
              if (refreshed) {
                final response = await _retry(e.requestOptions);
                return handler.resolve(response);
              }
            }

            // 🌟 Case B: CORE SECURITY GATEWAY (Admin Kickout or Token Hard Expire)
            // Agar token refresh fail ho gaya ya request pehle se hi retry thi, matlab session dead hai!
            log("🚨 Session Invalidated Globally. Force Logging Out User...");
            await _performForceLogout();
            return handler.next(e);
          }

          return handler.next(e);
        },
      ),
    );
  }

  // ================== FORCE LOGOUT HANDLER ==================

  Future<void> _performForceLogout() async {
    // 1. Storage ko completely clean karein
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'session_id');

    // 2. Global context use karke user ko login page par fenkein aur alert dikhayein
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars(); // Purane notifications hatao
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session revoked or expired. Logging out... 🛑"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      // Back button ko permanently flush karne ke liye context.go se redirect karein
      AppRouter.router.go('/login');
    }
  }

  // ================== STANDARD METHOD ENDPOINTS ==================

  Future<Response> get(String path, {Map<String, dynamic>? query, bool isPublic = false}) {
    return _dio.get(path, queryParameters: query, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> post(String path, {dynamic data, bool isPublic = false}) {
    return _dio.post(path, data: data, options: Options(extra: {"isPublic": isPublic}));
  }

  Future<Response> postMultipart(
      String path, {
        required Map<String, dynamic> fields,
        String? filePath,
        Uint8List? webBytes,
        String fileKey = "image",
        bool isPublic = false,
      }) async {
    final Map<String, dynamic> formDataMap = {...fields};

    if (kIsWeb) {
      if (webBytes != null && webBytes.isNotEmpty) {
        formDataMap[fileKey] = MultipartFile.fromBytes(
          webBytes,
          filename: 'web_upload_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }
    } else {
      if (filePath != null && filePath.isNotEmpty) {
        formDataMap[fileKey] = await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        );
      }
    }

    final FormData formData = FormData.fromMap(formDataMap);

    return _dio.post(
      path,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        extra: {"isPublic": isPublic},
      ),
    );
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

  // ================== SECURITY INTERCEPTOR HELPERS ==================

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

      // Note: Refresh call explicitly separate clean Dio instance se honi chahiye taaki main loop core triggers crash na hon
      final response = await Dio().post(
        "${Endpoints.baseUrl}/api/token/refresh/",
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