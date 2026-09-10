import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get username => _username;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _username = await _authService.getLoggedInUsername();
    }

    _isLoading = false;
    notifyListeners();
    return _isLoggedIn;
  }

  Future<bool> login(String usernameInput, String passwordInput) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.login(usernameInput, passwordInput);
      if (success) {
        _isLoggedIn = true;
        _username = usernameInput;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password. Default: admin / admin123';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.updatePassword(oldPassword, newPassword);
      _isLoading = false;
      if (!success) {
        _errorMessage = 'Current password does not match.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _isLoggedIn = false;
    _username = null;
    _errorMessage = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
