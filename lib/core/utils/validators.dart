class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final cleanValue = value.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleanValue)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? aadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Aadhaar is optional unless required
    }
    final cleanValue = value.trim().replaceAll(' ', '');
    if (!RegExp(r'^[0-9]{12}$').hasMatch(cleanValue)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  static String? grNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'GR Number is required';
    }
    if (value.trim().length < 2) {
      return 'GR Number must be at least 2 characters';
    }
    return null;
  }
}
