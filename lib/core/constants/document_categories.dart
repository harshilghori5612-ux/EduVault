class DocumentCategories {
  static const String studentPhoto = 'Student Photo';
  static const String aadhaarCard = 'Aadhaar Card';
  static const String birthCertificate = 'Birth Certificate';
  static const String schoolLeavingCertificate = 'School Leaving Certificate';
  static const String previousMarksheet = 'Previous Marksheet';
  static const String casteCertificate = 'Caste Certificate';
  static const String incomeCertificate = 'Income Certificate';
  static const String bankPassbook = 'Bank Passbook';
  static const String otherDocument = 'Other Document';

  static const List<String> defaultList = [
    studentPhoto,
    aadhaarCard,
    birthCertificate,
    schoolLeavingCertificate,
    previousMarksheet,
    casteCertificate,
    incomeCertificate,
    bankPassbook,
    otherDocument,
  ];

  /// Standard required documents for student document completion calculation
  static const List<String> requiredForCompletion = [
    studentPhoto,
    aadhaarCard,
    birthCertificate,
    schoolLeavingCertificate,
    previousMarksheet,
  ];
}
