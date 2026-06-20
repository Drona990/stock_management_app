import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String? access;
  final String? refresh;
  final String? userId;
  final String? username;
  final String? fullName;
  final String? role;
  final String? sessionId;

  AuthModel({
    this.access,
    this.refresh,
    this.userId,
    this.username,
    this.fullName,
    this.role,
    this.sessionId,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['access']?.toString() ?? "",
      refresh: json['refresh']?.toString() ?? "",
      userId: json['user_id']?.toString() ?? "",
      username: json['username']?.toString() ?? "",
      fullName: json['full_name']?.toString() ?? "",
      role: json['role']?.toString() ?? "",
      sessionId: json['session_id']?.toString() ?? "",
    );
  }

  AuthEntity toEntity() => AuthEntity(
    accessToken: access ?? "",
    refreshToken: refresh ?? "",
    userId: userId ?? "",
    fullName: fullName ?? "",
    role: role ?? "",
    sessionId: sessionId ?? "",
  );
}