class StudentModel {
  final String id;
  final String fullName;
  final String grNumber;
  final String? aadhaarNumber;
  final String dateOfBirth;
  final String gender;
  final String standard;
  final String division;
  final String academicYear;
  final String fatherName;
  final String motherName;
  final String mobileNumber;
  final String address;
  final String? photoPath;
  final String createdAt;
  final String updatedAt;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.grNumber,
    this.aadhaarNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.standard,
    required this.division,
    required this.academicYear,
    required this.fatherName,
    required this.motherName,
    required this.mobileNumber,
    required this.address,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'grNumber': grNumber,
      'aadhaarNumber': aadhaarNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'standard': standard,
      'division': division,
      'academicYear': academicYear,
      'fatherName': fatherName,
      'motherName': motherName,
      'mobileNumber': mobileNumber,
      'address': address,
      'photoPath': photoPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      grNumber: map['grNumber'] as String,
      aadhaarNumber: map['aadhaarNumber'] as String?,
      dateOfBirth: map['dateOfBirth'] as String,
      gender: map['gender'] as String,
      standard: map['standard'] as String,
      division: map['division'] as String,
      academicYear: map['academicYear'] as String,
      fatherName: map['fatherName'] as String,
      motherName: map['motherName'] as String,
      mobileNumber: map['mobileNumber'] as String,
      address: map['address'] as String,
      photoPath: map['photoPath'] as String?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  StudentModel copyWith({
    String? id,
    String? fullName,
    String? grNumber,
    String? aadhaarNumber,
    String? dateOfBirth,
    String? gender,
    String? standard,
    String? division,
    String? academicYear,
    String? fatherName,
    String? motherName,
    String? mobileNumber,
    String? address,
    String? photoPath,
    String? createdAt,
    String? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      grNumber: grNumber ?? this.grNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      standard: standard ?? this.standard,
      division: division ?? this.division,
      academicYear: academicYear ?? this.academicYear,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
