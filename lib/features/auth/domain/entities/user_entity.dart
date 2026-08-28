// domain/entities/user_entity.dart
class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String employeeId;
  final String empCode;
  final String fullName;
  final String? profilePhoto; // 🌟 Add this
  final String department;
  final String designation;
  final String shiftCode;
  final String shiftName;
  final String shiftStart;
  final String shiftEnd;

  AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.employeeId,
    required this.empCode,
    required this.fullName,
    this.profilePhoto,
    required this.department,
    required this.designation,
    required this.shiftCode,
    required this.shiftName,
    required this.shiftStart,
    required this.shiftEnd,
  });
}