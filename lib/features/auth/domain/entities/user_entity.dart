class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String fullName;
  final String role;
  final String sessionId;

  AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.sessionId,
  });
}