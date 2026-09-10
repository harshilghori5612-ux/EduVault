import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  /// Local authentication logic. Designed to be easily replaced with Laravel API calls.
  Future<bool> login(String username, String password) async {
    // Simulate slight network/processing delay for professional feel
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(AppConstants.prefAdminPassword) ?? AppConstants.defaultPassword;
    final savedUsername = prefs.getString(AppConstants.prefAdminUsername) ?? AppConstants.defaultUsername;

    if (username.trim() == savedUsername && password.trim() == savedPassword) {
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      await prefs.setString(AppConstants.prefAdminUsername, username.trim());
      return true;
    }
    return false;
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPassword = prefs.getString(AppConstants.prefAdminPassword) ?? AppConstants.defaultPassword;

    if (oldPassword.trim() == currentPassword) {
      await prefs.setString(AppConstants.prefAdminPassword, newPassword.trim());
      return true;
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
  }

  Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefAdminUsername);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    // Keep username & custom password saved so admin can log back in
  }
}
