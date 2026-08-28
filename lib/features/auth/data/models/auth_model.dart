// data/models/auth_model.dart
import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String? access;
  final String? refresh;
  final Map<String, dynamic>? user;

  AuthModel({this.access, this.refresh, this.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['access'],
      refresh: json['refresh'],
      user: json['user'],
    );
  }

  AuthEntity toEntity() {
    final userData = user ?? {};
    return AuthEntity(
      accessToken: access ?? '',
      refreshToken: refresh ?? '',
      userId: userData['id']?.toString() ?? '',
      employeeId: userData['employee_id']?.toString() ?? '',
      empCode: userData['emp_code']?.toString() ?? '',
      fullName: userData['full_name']?.toString() ?? '',
      profilePhoto: userData['profile_photo']?.toString(), // 🌟 Map profile_photo
      department: userData['department']?.toString() ?? '',
      designation: userData['designation']?.toString() ?? '',
      shiftCode: userData['shift_code']?.toString() ?? '',
      shiftName: userData['shift_name']?.toString() ?? '',
      shiftStart: userData['shift_start']?.toString() ?? '',
      shiftEnd: userData['shift_end']?.toString() ?? '',
    );
  }
}