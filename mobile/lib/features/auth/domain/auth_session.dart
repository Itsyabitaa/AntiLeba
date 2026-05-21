class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    this.fullName,
  });

  final String userId;
  final String email;
  final String accessToken;
  final String? fullName;
}
