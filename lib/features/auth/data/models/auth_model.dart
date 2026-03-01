import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String? access; // Nullable banayein
  final String? refresh; // Nullable banayein

  AuthModel({this.access, this.refresh});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Web Production mein response structure check karein
    // Agar 'data' key ke andar hai toh wahan se uthayein, warna root se
    final data = json['data'] as Map<String, dynamic>?;

    return AuthModel(
      access: data != null ? data['access']?.toString() : json['access']?.toString(),
      refresh: data != null ? data['refresh']?.toString() : json['refresh']?.toString(),
    );
  }

  AuthEntity toEntity() => AuthEntity(
    accessToken: access ?? "",
    refreshToken: refresh ?? "",
  );
}