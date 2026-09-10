import 'package:flutter/material.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';

enum StudentSortOption { nameAsc, nameDesc, grAsc, dateNewest }

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository;

  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  StudentSortOption _currentSort = StudentSortOption.dateNewest;

  List<StudentModel> get students => _filteredStudents;
  List<StudentModel> get allStudents => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  StudentSortOption get currentSort => _currentSort;

  StudentProvider({StudentRepository? repository})
      : _repository = repository ?? StudentRepository();

  Future<void> loadStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _repository.getAllStudents();
      _applySearchAndSort();
    } catch (e) {
      _errorMessage = 'Failed to load students: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchStudents(String query) {
    _searchQuery = query;
    _applySearchAndSort();
    notifyListeners();
  }

  void setSortOption(StudentSortOption option) {
    _currentSort = option;
    _applySearchAndSort();
    notifyListeners();
  }

  void _applySearchAndSort() {
    List<StudentModel> results = List.from(_students);

    // Apply Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      results = results.where((s) {
        final nameMatch = s.fullName.toLowerCase().contains(q);
        final grMatch = s.grNumber.toLowerCase().contains(q);
        final mobileMatch = s.mobileNumber.contains(q);
        final aadhaarMatch = (s.aadhaarNumber ?? '').contains(q);
        final stdMatch = s.standard.toLowerCase().contains(q);
        return nameMatch || grMatch || mobileMatch || aadhaarMatch || stdMatch;
      }).toList();
    }

    // Apply Sort
    switch (_currentSort) {
      case StudentSortOption.nameAsc:
        results.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case StudentSortOption.nameDesc:
        results.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case StudentSortOption.grAsc:
        results.sort((a, b) => a.grNumber.compareTo(b.grNumber));
        break;
      case StudentSortOption.dateNewest:
      default:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredStudents = results;
  }

  Future<bool> addStudent(StudentModel student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.addStudent(student);
      if (success) {
        await loadStudents();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(StudentModel student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.updateStudent(student);
      if (success) {
        await loadStudents();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteStudent(id);
      if (success) {
        await loadStudents();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete student: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  StudentModel? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
