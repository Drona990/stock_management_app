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
        "login": username,
        "password": password,
      },
    );

    return AuthModel.fromJson(response.data);
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