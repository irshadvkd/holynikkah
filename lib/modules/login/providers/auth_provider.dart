import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/modules/login/domain/auth_service.dart';

/// 🧭 Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = 'is_logged_in';

  bool _isLoggedIn = false;

  bool get isLoggedIn {
    AppLogger.info("Getting isLoggedIn: $_isLoggedIn", tag: "AuthProvider");
    return _isLoggedIn;
  }

  /// 🔹 Check login status
  Future<void> checkLoginStatus() async {
    AppLogger.info("Checking login status from storage...", tag: "AuthProvider");
    final value = await _storage.read(key: _key);
    AppLogger.info("Storage value for '$_key': $value", tag: "AuthProvider");
    _isLoggedIn = value == 'true';
    AppLogger.info("Set _isLoggedIn to: $_isLoggedIn", tag: "AuthProvider");
    notifyListeners();
    AppLogger.success("Login status check completed", tag: "AuthProvider");
  }

  /// 🔹 Send OTP (NOT login)
  Future<bool> sendOtp(String phone) async {
    AppLogger.info("Sending OTP to: $phone", tag: "AuthProvider");
    final result = await AuthService.instance.login(phone);
    AppLogger.info("OTP send result: $result", tag: "AuthProvider");
    return result;
  }

  /// 🔹 Mark user as logged in AFTER OTP
  Future<void> setLoggedIn() async {
    AppLogger.info("Setting user as logged in...", tag: "AuthProvider");
    _isLoggedIn = true;
    await _storage.write(key: _key, value: 'true');
    AppLogger.success("User marked as logged in and stored in storage", tag: "AuthProvider");
    notifyListeners();
  }

  /// 🔹 Logout
  Future<void> logout() async {
    AppLogger.info("Starting logout...", tag: "AuthProvider");
    await AuthService.instance.logout();
    _isLoggedIn = false;
    await _storage.delete(key: _key);
    AppLogger.success("Logout completed, cleared auth state", tag: "AuthProvider");
    notifyListeners();
  }

  /// 🔹 Clear all auth data (for testing)
  Future<void> clearAuthData() async {
    AppLogger.info("Clearing all auth data...", tag: "AuthProvider");
    _isLoggedIn = false;
    await _storage.deleteAll();
    AppLogger.success("All auth data cleared", tag: "AuthProvider");
    notifyListeners();
  }
}