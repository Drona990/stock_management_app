import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String access;
  final String refresh;

  AuthModel({required this.access, required this.refresh});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['data']['access'],
      refresh: json['data']['refresh'],
    );
  }

  AuthEntity toEntity() => AuthEntity(accessToken: access, refreshToken: refresh);
}