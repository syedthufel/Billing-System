class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final bool biometricEnabled;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.biometricEnabled,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
      biometricEnabled: json['biometricEnabled'] ?? false,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'isActive': isActive,
      'biometricEnabled': biometricEnabled,
    };
  }

  bool get isAdmin => role == 'admin';
}