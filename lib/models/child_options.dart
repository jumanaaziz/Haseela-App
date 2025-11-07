class ChildOption {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatar; // URL or null
  final String? email;
  final String username; // Username is mandatory

  ChildOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.email,
    required this.username,
  });

  factory ChildOption.fromFirestore(String id, Map<String, dynamic> data) {
    final String fn = (data['firstName'] ?? '').toString();
    final String ln = (data['lastName'] ?? '').toString();
    final String? av = (data['avatar'] as String?)?.trim();

    // Helper function to handle empty strings as null
    String? _trimOrNull(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return ChildOption(
      id: id,
      firstName: fn.trim(),
      lastName: ln.trim(),
      avatar: (av == null || av.isEmpty) ? null : av, // null if empty
      email: _trimOrNull(data['email'] as String?),
      username:
          _trimOrNull(data['username'] as String?) ??
          '', // Username is mandatory, fallback to empty string
    );
  }

  String get fullName =>
      [firstName, lastName].where((p) => p.trim().isNotEmpty).join(' ').trim();

  String get initial =>
      (firstName.trim().isNotEmpty) ? firstName.trim()[0].toUpperCase() : '?';
}
