import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/document_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudents} (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        grNumber TEXT NOT NULL UNIQUE,
        aadhaarNumber TEXT,
        dateOfBirth TEXT NOT NULL,
        gender TEXT NOT NULL,
        standard TEXT NOT NULL,
        division TEXT NOT NULL,
        academicYear TEXT NOT NULL,
        fatherName TEXT NOT NULL,
        motherName TEXT NOT NULL,
        mobileNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        photoPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableDocuments} (
        id TEXT PRIMARY KEY,
        studentId TEXT NOT NULL,
        documentName TEXT NOT NULL,
        category TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL,
        notes TEXT,
        uploadedAt TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES ${AppConstants.tableStudents} (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- STUDENT OPERATIONS ---

  Future<int> insertStudent(StudentModel student) async {
    final db = await instance.database;
    return await db.insert(
      AppConstants.tableStudents,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<int> updateStudent(StudentModel student) async {
    final db = await instance.database;
    return await db.update(
      AppConstants.tableStudents,
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(String id) async {
    final db = await instance.database;
    // Also cleanup document files on disk before deleting DB record
    final docs = await getDocumentsByStudentId(id);
    for (var doc in docs) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    return await db.delete(
      AppConstants.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudentModel>> getAllStudents() async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableStudents,
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => StudentModel.fromMap(json)).toList();
  }

  Future<StudentModel?> getStudentById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return StudentModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    final db = await instance.database;
    final cleanQuery = '%${query.trim()}%';
    final result = await db.query(
      AppConstants.tableStudents,
      where: '''
        fullName LIKE ? OR 
        grNumber LIKE ? OR 
        mobileNumber LIKE ? OR 
        aadhaarNumber LIKE ?
      ''',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery, cleanQuery],
      orderBy: 'fullName ASC',
    );
    return result.map((json) => StudentModel.fromMap(json)).toList();
  }

  Future<bool> checkDuplicateGrNumber(String grNumber, {String? excludeStudentId}) async {
    final db = await instance.database;
    String whereClause = 'grNumber = ?';
    List<dynamic> whereArgs = [grNumber.trim()];

    if (excludeStudentId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeStudentId);
    }

    final result = await db.query(
      AppConstants.tableStudents,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return result.isNotEmpty;
  }

  // --- DOCUMENT OPERATIONS ---

  Future<int> insertDocument(DocumentModel document) async {
    final db = await instance.database;
    return await db.insert(
      AppConstants.tableDocuments,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDocument(DocumentModel document) async {
    final db = await instance.database;
    return await db.update(
      AppConstants.tableDocuments,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> deleteDocument(String id) async {
    final db = await instance.database;
    final doc = await getDocumentById(id);
    if (doc != null) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    return await db.delete(
      AppConstants.tableDocuments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DocumentModel?> getDocumentById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableDocuments,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return DocumentModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<DocumentModel>> getDocumentsByStudentId(String studentId) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableDocuments,
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'uploadedAt DESC',
    );
    return result.map((json) => DocumentModel.fromMap(json)).toList();
  }

  Future<List<DocumentModel>> getAllDocuments() async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableDocuments,
      orderBy: 'uploadedAt DESC',
    );
    return result.map((json) => DocumentModel.fromMap(json)).toList();
  }

  // --- DASHBOARD QUERY OPERATIONS ---

  Future<int> getTotalStudents() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.tableStudents}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalDocuments() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.tableDocuments}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<StudentModel>> getRecentlyAddedStudents({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query(
      AppConstants.tableStudents,
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return result.map((json) => StudentModel.fromMap(json)).toList();
  }

  Future<int> getStudentsWithPendingDocumentsCount() async {
    final students = await getAllStudents();
    int pendingCount = 0;

    for (var student in students) {
      final docs = await getDocumentsByStudentId(student.id);
      // If student has fewer than 5 uploaded documents, consider pending
      if (docs.length < 5) {
        pendingCount++;
      }
    }
    return pendingCount;
  }

  /// Seeds demo student records for testing
  Future<int> seedSampleData() async {
    final db = await instance.database;
    final existingCount = await getTotalStudents();
    if (existingCount > 0) {
      return 0; // Don't overwrite existing data
    }

    final now = DateTime.now().toIso8601String();
    final sampleStudents = [
      StudentModel(
        id: 'seed-st-001',
        fullName: 'Aarav Rajesh Sharma',
        grNumber: 'GR-2026-101',
        aadhaarNumber: '453218907654',
        dateOfBirth: '15/06/2012',
        gender: 'Male',
        standard: 'Class 8',
        division: 'A',
        academicYear: '2025-2026',
        fatherName: 'Rajesh Sharma',
        motherName: 'Sunita Sharma',
        mobileNumber: '9876543210',
        address: 'Flat 402, Shanti Heights, M.G. Road, Pune',
        createdAt: now,
        updatedAt: now,
      ),
      StudentModel(
        id: 'seed-st-002',
        fullName: 'Ananya Suresh Patel',
        grNumber: 'GR-2026-102',
        aadhaarNumber: '789012345678',
        dateOfBirth: '22/09/2014',
        gender: 'Female',
        standard: 'Class 5',
        division: 'B',
        academicYear: '2025-2026',
        fatherName: 'Suresh Patel',
        motherName: 'Meena Patel',
        mobileNumber: '9123456780',
        address: 'B-12, Gokul Dham Society, Satellite, Ahmedabad',
        createdAt: now,
        updatedAt: now,
      ),
      StudentModel(
        id: 'seed-st-003',
        fullName: 'Rohan Vikram Deshmukh',
        grNumber: 'GR-2026-103',
        aadhaarNumber: '345678901234',
        dateOfBirth: '10/01/2010',
        gender: 'Male',
        standard: 'Class 10',
        division: 'A',
        academicYear: '2025-2026',
        fatherName: 'Vikram Deshmukh',
        motherName: 'Pooja Deshmukh',
        mobileNumber: '9988776655',
        address: 'Plot 78, Shivaji Nagar, Nagpur',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    int inserted = 0;
    for (var st in sampleStudents) {
      await insertStudent(st);
      inserted++;
    }
    return inserted;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
