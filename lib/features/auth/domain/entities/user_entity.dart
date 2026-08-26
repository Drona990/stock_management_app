class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String employeeId;
  final String empCode;
  final String fullName;
  final String department;
  final String designation;
  final String shiftName;
  final String shiftCode;
  final String shiftStart;
  final String shiftEnd;
  final int graceMinutes;

  AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.employeeId,
    required this.empCode,
    required this.fullName,
    required this.department,
    required this.designation,
    required this.shiftName,
    required this.shiftCode,
    required this.shiftStart,
    required this.shiftEnd,
    required this.graceMinutes,
  });
}