class ChildOption {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatar; // URL or null
  final String? email;
  final String? username;

  ChildOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.email,
    this.username,
  });

  factory ChildOption.fromFirestore(String id, Map<String, dynamic> data) {
    final String fn = (data['firstName'] ?? '').toString();
    final String ln = (data['lastName'] ?? '').toString();
    final String? av = (data['avatar'] as String?)?.trim();

    return ChildOption(
      id: id,
      firstName: fn,
      lastName: ln,
      avatar: (av == null || av.isEmpty) ? null : av, // null if empty
      email: (data['email'] as String?)?.trim(),
      username: (data['username'] as String?)?.trim(),
    );
  }

  String get fullName =>
      [firstName, lastName].where((p) => p.trim().isNotEmpty).join(' ').trim();

  String get initial =>
      (firstName.trim().isNotEmpty) ? firstName.trim()[0].toUpperCase() : '?';
}
