import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper;

  StudentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<StudentModel>> getAllStudents() async {
    return await _dbHelper.getAllStudents();
  }

  Future<StudentModel?> getStudentById(String id) async {
    return await _dbHelper.getStudentById(id);
  }

  Future<bool> addStudent(StudentModel student) async {
    final isDuplicate = await _dbHelper.checkDuplicateGrNumber(student.grNumber);
    if (isDuplicate) {
      throw Exception('GR Number "${student.grNumber}" already exists.');
    }
    final result = await _dbHelper.insertStudent(student);
    return result > 0;
  }

  Future<bool> updateStudent(StudentModel student) async {
    final isDuplicate = await _dbHelper.checkDuplicateGrNumber(
      student.grNumber,
      excludeStudentId: student.id,
    );
    if (isDuplicate) {
      throw Exception('GR Number "${student.grNumber}" is assigned to another student.');
    }
    final result = await _dbHelper.updateStudent(student);
    return result > 0;
  }

  Future<bool> deleteStudent(String id) async {
    final result = await _dbHelper.deleteStudent(id);
    return result > 0;
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    if (query.trim().isEmpty) {
      return await getAllStudents();
    }
    return await _dbHelper.searchStudents(query);
  }

  Future<bool> isGrNumberDuplicate(String grNumber, {String? excludeId}) async {
    return await _dbHelper.checkDuplicateGrNumber(grNumber, excludeStudentId: excludeId);
  }
}
