import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String? access;
  final String? refresh;

  AuthModel({this.access, this.refresh});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['access']?.toString() ?? "",
      refresh: json['refresh']?.toString() ?? "",
    );
  }
  AuthEntity toEntity() => AuthEntity(
    accessToken: access ?? "",
    refreshToken: refresh ?? "",
  );
}