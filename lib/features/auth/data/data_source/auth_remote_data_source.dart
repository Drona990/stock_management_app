import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_model.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  // 1. Standard Credentials Login API
  Future<AuthModel> login(String username, String password) async {
    final Response response = await apiClient.post(
      "/api/auth/login/",
      isPublic: true,
      data: {
        "username": username,
        "password": password,
      },
    );

    final responseData = response.data;

    if (responseData != null) {
      if (responseData['success'] == true && responseData['data'] != null) {
        return AuthModel.fromJson(responseData['data']);
      } else if (responseData['access'] != null) {
        return AuthModel.fromJson(responseData);
      }
    }

    throw Exception(
      responseData?['message'] ??
          responseData?['error'] ??
          responseData?['detail'] ??
          "Authentication Failed",
    );
  }

  // 2. Instant QR Code Login API (Employee App)
  Future<AuthModel> loginWithQR(String qrToken) async {
    final Response response = await apiClient.post(
      "/api/hrms/auth/qr-login/",
      isPublic: true,
      data: {
        "qr_token": qrToken,
      },
    );

    final responseData = response.data;

    if (responseData != null) {
      if (responseData['success'] == true && responseData['data'] != null) {
        return AuthModel.fromJson(responseData['data']);
      } else if (responseData['access'] != null) {
        return AuthModel.fromJson(responseData);
      }
    }

    throw Exception(
      responseData?['error'] ??
          responseData?['message'] ??
          "Invalid or Expired QR Pass",
    );
  }

  // 3. Employee Dashboard & Duty Metrics
  Future<Response> getUserDashboard() async {
    final Response response = await apiClient.get(
      "/api/user/dashboard/",
    );
    return response;
  }

  // 4. Push Notification Token Sync
  Future<void> updateFCMToken(String fcmToken) async {
    await apiClient.post(
      "/api/user/update-fcm-token/",
      data: {"fcm_token": fcmToken},
    );
  }
}