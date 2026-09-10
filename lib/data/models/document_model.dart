class DocumentModel {
  final String id;
  final String studentId;
  final String documentName;
  final String category;
  final String filePath;
  final String fileType; // 'image' or 'pdf' or 'other'
  final String? notes;
  final String uploadedAt;

  DocumentModel({
    required this.id,
    required this.studentId,
    required this.documentName,
    required this.category,
    required this.filePath,
    required this.fileType,
    this.notes,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'documentName': documentName,
      'category': category,
      'filePath': filePath,
      'fileType': fileType,
      'notes': notes,
      'uploadedAt': uploadedAt,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      documentName: map['documentName'] as String,
      category: map['category'] as String,
      filePath: map['filePath'] as String,
      fileType: map['fileType'] as String,
      notes: map['notes'] as String?,
      uploadedAt: map['uploadedAt'] as String,
    );
  }

  DocumentModel copyWith({
    String? id,
    String? studentId,
    String? documentName,
    String? category,
    String? filePath,
    String? fileType,
    String? notes,
    String? uploadedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      documentName: documentName ?? this.documentName,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      notes: notes ?? this.notes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
