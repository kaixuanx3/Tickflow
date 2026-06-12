class AuthUser {
  const AuthUser({required this.id, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      AuthUser(id: json['id'] as String, email: json['email'] as String);

  final String id;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
