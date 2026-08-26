import '../../domain/entities/user_entity.dart';

class AuthModel {
  final String? access;
  final String? refresh;
  final Map<String, dynamic>? user;

  AuthModel({this.access, this.refresh, this.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
      user: json['user'] as Map<String, dynamic>?,
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
      fullName: userData['full_name']?.toString() ?? 'Employee',
      department: userData['department']?.toString() ?? 'General',
      designation: userData['designation']?.toString() ?? 'Staff',
      shiftName: userData['shift_name']?.toString() ?? 'General Shift',
      shiftCode: userData['shift_code']?.toString() ?? 'GS-01',
      shiftStart: userData['shift_start']?.toString() ?? '09:30:00',
      shiftEnd: userData['shift_end']?.toString() ?? '18:30:00',
      graceMinutes: int.tryParse(userData['grace_minutes']?.toString() ?? '15') ?? 15,
    );
  }
}