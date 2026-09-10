import '../database/database_helper.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final DatabaseHelper _dbHelper;

  DocumentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<DocumentModel>> getDocumentsByStudentId(String studentId) async {
    return await _dbHelper.getDocumentsByStudentId(studentId);
  }

  Future<DocumentModel?> getDocumentById(String id) async {
    return await _dbHelper.getDocumentById(id);
  }

  Future<List<DocumentModel>> getAllDocuments() async {
    return await _dbHelper.getAllDocuments();
  }

  Future<bool> addDocument(DocumentModel document) async {
    final result = await _dbHelper.insertDocument(document);
    return result > 0;
  }

  Future<bool> updateDocument(DocumentModel document) async {
    final result = await _dbHelper.updateDocument(document);
    return result > 0;
  }

  Future<bool> deleteDocument(String id) async {
    final result = await _dbHelper.deleteDocument(id);
    return result > 0;
  }
}
