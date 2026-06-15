class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    this.fullName,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AuthSession(
      userId: (user['id'] ?? json['userId']) as String,
      email: (user['email'] ?? json['email']) as String,
      accessToken: (json['accessToken'] ?? json['access_token']) as String,
      fullName: user['fullName'] as String? ?? json['fullName'] as String?,
    );
  }

  final String userId;
  final String email;
  final String accessToken;
  final String? fullName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'email': email,
        'accessToken': accessToken,
        'fullName': fullName,
      };
}
