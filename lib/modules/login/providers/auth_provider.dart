/// 🔥 AuthProvider (VIP + NORMAL - FULL CLEAN VERSION)

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/modules/login/domain/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  /// 🔥 Storage Keys
  static const String _vipLoginKey = 'is_vip_logged_in';
  static const String _normalLoginKey = 'is_normal_logged_in';

  /// 🔥 Private States
  bool _isVipLoggedIn = false;
  bool _isNormalLoggedIn = false;
  bool _isLoading = false;

  /// ============================
  /// 🔥 GETTERS
  /// ============================

  /// 🔹 VIP Login Status
  bool get isVipLoggedIn => _isVipLoggedIn;

  /// 🔹 NORMAL Login Status
  bool get isNormalLoggedIn => _isNormalLoggedIn;

  /// 🔹 Combined (Optional)
  bool get isAnyUserLoggedIn => _isVipLoggedIn || _isNormalLoggedIn;

  /// 🔹 Loading State
  bool get isLoading => _isLoading;

  /// ============================
  /// 🔥 INIT / CHECK LOGIN
  /// ============================

  /// 🔹 Check both login states from storage
  Future<void> checkLoginStatus() async {
    AppLogger.info("Checking login status...", tag: "AuthProvider");

    final vipValue = await _storage.read(key: _vipLoginKey);
    final normalValue = await _storage.read(key: _normalLoginKey);

    _isVipLoggedIn = vipValue == 'true';
    _isNormalLoggedIn = normalValue == 'true';

    AppLogger.info(
      "VIP: $_isVipLoggedIn | NORMAL: $_isNormalLoggedIn",
      tag: "AuthProvider",
    );

    notifyListeners();
  }

  /// ============================
  /// 🔥 OTP
  /// ============================

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.info("Sending OTP to: $phone", tag: "AuthProvider");

    final result = await AuthService.instance.login(phone);

    _isLoading = false;
    notifyListeners();

    return result;
  }

  /// ============================
  /// 🔥 LOGIN METHODS
  /// ============================

  /// 🔹 VIP LOGIN
  Future<void> setVipLoggedIn() async {
    AppLogger.info("Setting VIP login...", tag: "AuthProvider");

    _isVipLoggedIn = true;

    await _storage.write(key: _vipLoginKey, value: 'true');

    AppLogger.success("VIP user logged in", tag: "AuthProvider");

    notifyListeners();
  }

  /// 🔹 NORMAL LOGIN
  Future<void> setNormalLoggedIn() async {
    AppLogger.info("Setting NORMAL login...", tag: "AuthProvider");

    _isNormalLoggedIn = true;

    await _storage.write(key: _normalLoginKey, value: 'true');

    AppLogger.success("Normal user logged in", tag: "AuthProvider");

    notifyListeners();
  }

  /// ============================
  /// 🔥 LOGOUT METHODS
  /// ============================

  /// 🔹 LOGOUT VIP ONLY
  Future<void> logoutVip() async {
    AppLogger.info("Logging out VIP...", tag: "AuthProvider");

    _isVipLoggedIn = false;

    await _storage.delete(key: _vipLoginKey);

    notifyListeners();
  }

  /// 🔹 LOGOUT NORMAL ONLY
  Future<void> logoutNormal() async {
    AppLogger.info("Logging out NORMAL...", tag: "AuthProvider");

    _isNormalLoggedIn = false;

    await _storage.delete(key: _normalLoginKey);

    notifyListeners();
  }

  /// 🔹 LOGOUT ALL
  Future<void> logoutAll() async {
    AppLogger.info("Logging out ALL users...", tag: "AuthProvider");

    await AuthService.instance.logout();

    _isVipLoggedIn = false;
    _isNormalLoggedIn = false;

    await _storage.delete(key: _vipLoginKey);
    await _storage.delete(key: _normalLoginKey);

    AppLogger.success("All users logged out", tag: "AuthProvider");

    notifyListeners();
  }

  /// ============================
  /// 🔥 CLEAR (DEV ONLY)
  /// ============================

  Future<void> clearAuthData() async {
    AppLogger.info("Clearing all auth data...", tag: "AuthProvider");

    _isVipLoggedIn = false;
    _isNormalLoggedIn = false;

    await _storage.deleteAll();

    notifyListeners();
  }
}