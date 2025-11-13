import 'package:flutter/material.dart';
import 'package:holynikkah/modules/auth/domain/auth_service.dart';

/// 🧭 Provider for managing authentication state (login/signup/logout)
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// Login user
  Future<bool> login(String email, String password) async {
    final result = await AuthService.instance.login(email, password);
    _isLoggedIn = result;
    notifyListeners();
    return result;
  }

  /// Signup user
  Future<bool> signup(String email, String password, String name) async {
    final result = await AuthService.instance.signup(email, password, name);
    notifyListeners();
    return result;
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    final result = await AuthService.instance.forgotPassword(email);
    return result;
  }

  /// Logout user
  Future<void> logout() async {
    await AuthService.instance.logout();
    _isLoggedIn = false;
    notifyListeners();
  }
}
