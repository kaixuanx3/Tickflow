class AuthUser {
  const AuthUser({required this.id, required this.email, this.name});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
      );

  final String id;
  final String email;

  /// Display name, or null until the user sets one.
  final String? name;

  /// What to show as the account's primary label: the name if set, else email.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : email;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}
