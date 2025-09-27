class ParentProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final String? avatar;

  ParentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.avatar,
  });

  factory ParentProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return ParentProfile(
      id: id,
      firstName: (data['firstName'] ?? '').toString(),
      lastName: (data['lastName'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      password: (data['password'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      avatar: (data['avatar'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
    };
  }

  String get fullName => '$firstName $lastName';

  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  // Validation methods
  static String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (value.length > 30) {
      return 'First name must be at most 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'First name can only contain letters';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (value.length > 30) {
      return 'Last name must be at most 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Last name can only contain letters';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 2) {
      return 'Username must be at least 2 characters';
    }
    if (value.length > 30) {
      return 'Username must be at most 30 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.com')) {
      return 'Email must contain @ and .com';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    // Check if password starts with special character or number
    if (RegExp(r'^[!@#$%^&*(),.?":{}|<>0-9]').hasMatch(value)) {
      return 'Password cannot start with special character or number';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!value.startsWith('05') || value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number must be 10 digits starting with 05';
    }
    return null;
  }

  ParentProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    String? avatar,
  }) {
    return ParentProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
    );
  }
}
