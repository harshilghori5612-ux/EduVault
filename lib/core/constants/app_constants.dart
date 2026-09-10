class AppConstants {
  static const String appName = 'EduVault';
  static const String appTagline = 'Secure Student Details & Documents';
  static const String appVersion = '1.0.0';

  // Auth Constants
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefAdminUsername = 'admin_username';
  static const String prefAdminPassword = 'admin_password';
  static const String prefIsDarkMode = 'is_dark_mode';

  // Database Constants
  static const String dbName = 'eduvault.db';
  static const int dbVersion = 1;

  static const String tableStudents = 'students';
  static const String tableDocuments = 'documents';

  // Dropdown Lists
  static const List<String> genders = ['Male', 'Female', 'Other'];
  static const List<String> standards = [
    'Nursery',
    'LKG',
    'UKG',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
  ];
  static const List<String> divisions = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const List<String> academicYears = [
    '2023-2024',
    '2024-2025',
    '2025-2026',
    '2026-2027',
  ];
}
