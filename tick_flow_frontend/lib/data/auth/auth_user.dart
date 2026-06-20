class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.hasPassword,
    this.pushEnabled,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        hasPassword: json['hasPassword'] as bool?,
        pushEnabled: json['pushEnabled'] as bool?,
      );

  final String id;
  final String email;

  /// Display name, or null until the user sets one.
  final String? name;

  /// Whether the account has a password (false = Google-only). Null for sessions
  /// saved before this field existed — callers treat unknown as "has one".
  final bool? hasPassword;

  /// Whether alert push is enabled. Null for older sessions — treated as on.
  final bool? pushEnabled;

  /// What to show as the account's primary label: the name if set, else email.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'hasPassword': hasPassword,
        'pushEnabled': pushEnabled,
      };
}
