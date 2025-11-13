import 'dart:async';
import 'package:holynikkah/core/utils/app_logger.dart';

/// 🧭 Service responsible for authentication logic.
/// Handles API calls, validation, or any business rules.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Simulated login API
  /// Returns `true` if login succeeds, else `false`.
  Future<bool> login(String email, String password) async {
    AppLogger.info("Attempting login for $email", tag: "AuthService");
    await Future.delayed(const Duration(seconds: 2)); // simulate network delay

    // TODO: Replace with real API call
    final success = email == "test@example.com" && password == "123456";

    if (success) {
      AppLogger.success("Login successful for $email", tag: "AuthService");
    } else {
      AppLogger.warning("Login failed for $email", tag: "AuthService");
    }

    return success;
  }

  /// Simulated logout
  Future<void> logout() async {
    AppLogger.info("Logging out user", tag: "AuthService");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Simulated signup
  Future<bool> signup(String email, String password, String name) async {
    AppLogger.info("Attempting signup for $email", tag: "AuthService");
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with real API call
    final success = email.isNotEmpty && password.isNotEmpty && name.isNotEmpty;
    success
        ? AppLogger.success("Signup successful for $email", tag: "AuthService")
        : AppLogger.warning("Signup failed for $email", tag: "AuthService");

    return success;
  }

  /// Simulated forgot password
  Future<bool> forgotPassword(String email) async {
    AppLogger.info("Forgot password requested for $email", tag: "AuthService");
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with real API call
    final success = email.isNotEmpty;
    success
        ? AppLogger.success("Reset email sent to $email", tag: "AuthService")
        : AppLogger.warning(
            "Failed to send reset email to $email",
            tag: "AuthService",
          );

    return success;
  }
}
