class ValidationUtils {
  // First Name / Last Name validation
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return fieldName == 'First name'
          ? 'First name is required'
          : 'Last name is required';
    }

    // Check if only letters (including Arabic letters, no spaces, numbers, or special characters)
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF]+$').hasMatch(value)) {
      return fieldName == 'First name'
          ? 'First name can only contain letters'
          : 'Last name can only contain letters';
    }

    // Check length between 2 and 30 characters
    if (value.length < 2) {
      return fieldName == 'First name'
          ? 'First name must be at least 2 characters long'
          : 'Last name must be at least 2 characters long';
    }

    if (value.length > 30) {
      return fieldName == 'First name'
          ? 'First name must be no more than 30 characters long'
          : 'Last name must be no more than 30 characters long';
    }

    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    // Check for spaces
    if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }

    // Check if only letters, numbers, or underscore
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    // Check if starts with letter (not number or special character)
    if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
      return 'Username must start with a letter';
    }

    // Check length between 4 and 20 characters
    if (value.length < 4) {
      return 'Username must be at least 4 characters long';
    }

    if (value.length > 20) {
      return 'Username must be no more than 20 characters long';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Check if email contains @ and .com
    if (!value.contains('@')) {
      return 'Email must contain @';
    }

    if (!value.contains('.com')) {
      return 'Email must contain .com';
    }

    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Check email length (reasonable limit)
    if (value.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Check minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check maximum length (reasonable limit)
    if (value.length > 128) {
      return 'Password is too long';
    }

    // Check for at least one uppercase letter (A-Z)
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }

    // Check for at least one lowercase letter (a-z)
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }

    // Check for at least one number (0-9)
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number (0-9)';
    }

    // Check for at least one special character (!@#$%^&*)
    if (!RegExp(r'[!@#\$%\^&\*]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Saudi phone number (starts with 05 and is exactly 10 digits)
    if (!RegExp(r'^05\d{8}$').hasMatch(cleanPhone)) {
      return 'Phone number must start with 05 and be exactly 10 digits';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // General text field validation (for optional fields)
  static String? validateOptionalText(
    String? value,
    String fieldName, {
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Optional field, so empty is valid
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must be no more than $maxLength characters long';
    }

    return null;
  }

  // Validate form completeness
  static bool isFormValid(Map<String, String?> validations) {
    return validations.values.every((validation) => validation == null);
  }

  // Get all validation errors
  static List<String> getAllErrors(Map<String, String?> validations) {
    return validations.values
        .where((validation) => validation != null)
        .cast<String>()
        .toList();
  }
}
