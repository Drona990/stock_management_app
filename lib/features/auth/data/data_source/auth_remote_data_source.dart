import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_model.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

// 1. Login API
  Future<AuthModel> login(String username, String password) async {
    final Response response = await apiClient.post(
      "/api/auth/login/",
      isPublic: true,
      data: {
        "username": username,
        "password": password,
      },
    );

    print("login response $response");

    final responseData = response.data;

    if (responseData != null) {
      if (responseData['success'] == true && responseData['data'] != null) {
        return AuthModel.fromJson(responseData['data']);
      } else if (responseData['access'] != null) {
        return AuthModel.fromJson(responseData);
      }
    }

    // Agar bilkul hi empty response ho tabhi exception throw hoga
    throw Exception(responseData?['message'] ?? responseData?['errors']?.toString() ?? "Login Failed");
  }
  Future<void> updateFCMToken(String fcmToken) async {
    await apiClient.post(
      "/api/user/update-fcm-token/",
      data: {"fcm_token": fcmToken},
    );
  }

  Future<Response> getUserDashboard() async {
    final Response response = await apiClient.get(
      "/api/user/dashboard/",
    );
    return response;
  }
}