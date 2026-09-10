import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/constants/document_categories.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_repository.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _repository;

  List<DocumentModel> _studentDocuments = [];
  List<DocumentModel> _allDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get studentDocuments => _studentDocuments;
  List<DocumentModel> get allDocuments => _allDocuments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DocumentProvider({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository();

  Future<void> loadDocumentsForStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _studentDocuments = await _repository.getDocumentsByStudentId(studentId);
    } catch (e) {
      _errorMessage = 'Failed to load documents: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allDocuments = await _repository.getAllDocuments();
    } catch (e) {
      _errorMessage = 'Failed to load all documents: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DocumentModel?> saveDocumentFile({
    required String studentId,
    required String documentName,
    required String category,
    required String sourceFilePath,
    required String fileType,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Copy source file into application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(appDir.path, 'EduVault_Documents', studentId));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final fileExt = p.extension(sourceFilePath);
      final uniqueFileName = '${const Uuid().v4()}$fileExt';
      final targetPath = p.join(docsDir.path, uniqueFileName);

      final sourceFile = File(sourceFilePath);
      await sourceFile.copy(targetPath);

      // 2. Create DocumentModel
      final docModel = DocumentModel(
        id: const Uuid().v4(),
        studentId: studentId,
        documentName: documentName,
        category: category,
        filePath: targetPath,
        fileType: fileType,
        notes: notes,
        uploadedAt: DateTime.now().toIso8601String(),
      );

      // 3. Save to database
      await _repository.addDocument(docModel);
      await loadDocumentsForStudent(studentId);
      return docModel;
    } catch (e) {
      _errorMessage = 'Failed to save document: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<DocumentModel?> replaceDocumentFile({
    required DocumentModel oldDocument,
    required String newSourceFilePath,
    required String newFileType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Copy new source file
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(appDir.path, 'EduVault_Documents', oldDocument.studentId));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final fileExt = p.extension(newSourceFilePath);
      final uniqueFileName = '${const Uuid().v4()}$fileExt';
      final newTargetPath = p.join(docsDir.path, uniqueFileName);

      await File(newSourceFilePath).copy(newTargetPath);

      // 2. Remove old physical file if exists
      final oldFile = File(oldDocument.filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // 3. Update DocumentModel
      final updatedDoc = oldDocument.copyWith(
        filePath: newTargetPath,
        fileType: newFileType,
        uploadedAt: DateTime.now().toIso8601String(),
      );

      await _repository.updateDocument(updatedDoc);
      await loadDocumentsForStudent(oldDocument.studentId);
      return updatedDoc;
    } catch (e) {
      _errorMessage = 'Failed to replace document: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteDocument(String id, String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteDocument(id);
      if (success) {
        await loadDocumentsForStudent(studentId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete document: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculates document completion percentage for a student based on required categories
  double calculateCompletionPercentage(List<DocumentModel> studentDocs) {
    if (DocumentCategories.requiredForCompletion.isEmpty) return 0.0;
    final uploadedCategories = studentDocs.map((d) => d.category).toSet();

    int matchedCount = 0;
    for (var cat in DocumentCategories.requiredForCompletion) {
      if (uploadedCategories.contains(cat)) {
        matchedCount++;
      }
    }
    return matchedCount / DocumentCategories.requiredForCompletion.length;
  }

  /// Helper to get list of pending required categories for a student
  List<String> getPendingCategories(List<DocumentModel> studentDocs) {
    final uploadedCategories = studentDocs.map((d) => d.category).toSet();
    return DocumentCategories.defaultList
        .where((cat) => !uploadedCategories.contains(cat))
        .toList();
  }
}
