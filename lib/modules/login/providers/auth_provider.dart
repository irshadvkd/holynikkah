/// 🔥 AuthProvider (VIP + NORMAL - FULL CLEAN VERSION)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/services/category_session_storage.dart';
import 'package:holynikkah/core/services/template_session_storage.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/modules/login/domain/auth_service.dart';
import 'package:holynikkah/modules/registration/models/vip_user_fields.dart';
import 'package:holynikkah/modules/registration/services/normal_otp_service.dart';
import 'package:holynikkah/modules/registration/services/vip_otp_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  /// 🔥 Storage Keys
  static const String _vipLoginKey = 'is_vip_logged_in';
  static const String _normalLoginKey = 'is_normal_logged_in';
  static const String _vipAuthTokenKey = 'vip_auth_token';
  static const String _vipUserKey = 'vip_user';
  static const String _normalAuthTokenKey = 'normal_auth_token';
  static const String _normalUserKey = 'normal_user';

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
    final token = await _storage.read(key: _vipAuthTokenKey);

    _isVipLoggedIn = vipValue == 'true';
    _isNormalLoggedIn = normalValue == 'true';

    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
    } else if (_isNormalLoggedIn) {
      final normalToken = await _storage.read(key: _normalAuthTokenKey);
      if (normalToken != null && normalToken.isNotEmpty) {
        ApiClient.instance.setAuthToken(normalToken);
      }
    }

    await _syncVipCategoryFromStoredUser();
    await _syncNormalCategoryFromStoredUser();
    await _syncVipTemplateFromStoredUser();
    await _syncNormalTemplateFromStoredUser();

    AppLogger.info(
      "VIP: $_isVipLoggedIn | NORMAL: $_isNormalLoggedIn",
      tag: "AuthProvider",
    );

    notifyListeners();
  }

  /// ============================
  /// 🔥 OTP
  /// ============================

  Future<OtpActionResult> sendOtp(String phone, {required String type}) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.info("Sending OTP to: $phone (type: $type)", tag: "AuthProvider");

    OtpActionResult result;
    if (type == 'vip') {
      final response = await VipOtpService.instance.sendOtp(phone);
      result = OtpActionResult(
        success: response.status && (response.data?.otpSent ?? false),
        message: response.message.isNotEmpty
            ? response.message
            : 'Failed to send OTP',
      );
    } else {
      final response = await NormalOtpService.instance.sendOtp(phone);
      result = OtpActionResult(
        success: response.status && (response.data?.otpSent ?? false),
        message: response.message.isNotEmpty
            ? response.message
            : 'Failed to send OTP',
      );
    }

    _isLoading = false;
    notifyListeners();

    return result;
  }

  Future<OtpActionResult> resendOtp(String phone, {required String type}) async {
    if (type == 'vip') {
      _isLoading = true;
      notifyListeners();

      AppLogger.info("Resending OTP to: $phone (type: $type)", tag: "AuthProvider");

      final response = await VipOtpService.instance.resendOtp(phone);
      final result = OtpActionResult(
        success: response.status && (response.data?.otpSent ?? false),
        message: response.message.isNotEmpty
            ? response.message
            : 'Failed to resend OTP',
      );

      _isLoading = false;
      notifyListeners();

      return result;
    }

    return sendOtp(phone, type: type);
  }

  /// ============================
  /// 🔥 LOGIN METHODS
  /// ============================

  /// 🔹 VIP LOGIN
  Future<void> setVipLoggedIn({
    String? token,
    Map<String, dynamic>? user,
  }) async {
    AppLogger.info("Setting VIP login...", tag: "AuthProvider");

    _isVipLoggedIn = true;

    await _storage.write(key: _vipLoginKey, value: 'true');

    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _vipAuthTokenKey, value: token);
      ApiClient.instance.setAuthToken(token);
    }

    if (user != null && user.isNotEmpty) {
      await _storage.write(key: _vipUserKey, value: jsonEncode(user));
      await CategorySessionStorage().setVipCategorySelected(
        VipUserFields.isCategorySelected(user),
      );
      await TemplateSessionStorage().setVipTemplateSelected(
        VipUserFields.isTemplateSelected(user),
      );
    }

    AppLogger.success("VIP user logged in", tag: "AuthProvider");

    notifyListeners();
  }

  /// 🔹 NORMAL LOGIN
  Future<void> setNormalLoggedIn({
    String? token,
    Map<String, dynamic>? user,
  }) async {
    AppLogger.info("Setting NORMAL login...", tag: "AuthProvider");

    _isNormalLoggedIn = true;

    await _storage.write(key: _normalLoginKey, value: 'true');

    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _normalAuthTokenKey, value: token);
      ApiClient.instance.setAuthToken(token);
    }

    if (user != null && user.isNotEmpty) {
      await _storage.write(key: _normalUserKey, value: jsonEncode(user));
      await CategorySessionStorage().setNormalCategorySelected(
        VipUserFields.isCategorySelected(user),
      );
      await TemplateSessionStorage().setNormalTemplateSelected(
        VipUserFields.isTemplateSelected(user),
      );
    }

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
    await _storage.delete(key: _vipAuthTokenKey);
    await _storage.delete(key: _vipUserKey);
    ApiClient.instance.setAuthToken(null);
    await CategorySessionStorage().setVipCategorySelected(false);
    await TemplateSessionStorage().setVipTemplateSelected(false);

    notifyListeners();
  }

  /// 🔹 LOGOUT NORMAL ONLY
  Future<void> logoutNormal() async {
    AppLogger.info("Logging out NORMAL...", tag: "AuthProvider");

    _isNormalLoggedIn = false;

    await _storage.delete(key: _normalLoginKey);
    await _storage.delete(key: _normalAuthTokenKey);
    await _storage.delete(key: _normalUserKey);
    await CategorySessionStorage().setNormalCategorySelected(false);
    await TemplateSessionStorage().setNormalTemplateSelected(false);

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
    await _storage.delete(key: _normalAuthTokenKey);
    await _storage.delete(key: _normalUserKey);
    ApiClient.instance.setAuthToken(null);
    await CategorySessionStorage().setVipCategorySelected(false);
    await CategorySessionStorage().setNormalCategorySelected(false);
    await TemplateSessionStorage().clearAllTemplateSelections();

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

  Future<void> _syncVipCategoryFromStoredUser() async {
    final userJson = await _storage.read(key: _vipUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      await CategorySessionStorage().setVipCategorySelected(
        VipUserFields.isCategorySelected(user),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to sync VIP category from stored user: $e',
        tag: 'AuthProvider',
      );
    }
  }

  Future<void> _syncNormalCategoryFromStoredUser() async {
    final userJson = await _storage.read(key: _normalUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      await CategorySessionStorage().setNormalCategorySelected(
        VipUserFields.isCategorySelected(user),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to sync normal category from stored user: $e',
        tag: 'AuthProvider',
      );
    }
  }

  /// Use the correct bearer token before VIP/normal authenticated API calls.
  Future<void> ensureApiTokenFor({required bool isVip}) async {
    final key = isVip ? _vipAuthTokenKey : _normalAuthTokenKey;
    final token = await _storage.read(key: key);
    ApiClient.instance.setAuthToken(token);
  }

  /// Persist category selection on the stored VIP user profile.
  Future<void> updateStoredVipCategorySelected(bool isSelected) async {
    await CategorySessionStorage().setVipCategorySelected(isSelected);

    final userJson = await _storage.read(key: _vipUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
      user['is_category_selected'] = isSelected;
      await _storage.write(key: _vipUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning(
        'Failed to update stored VIP category flag: $e',
        tag: 'AuthProvider',
      );
    }
  }

  /// Persist category selection on the stored normal user profile.
  Future<void> updateStoredNormalCategorySelected(bool isSelected) async {
    await CategorySessionStorage().setNormalCategorySelected(isSelected);

    final userJson = await _storage.read(key: _normalUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
      user['is_category_selected'] = isSelected;
      await _storage.write(key: _normalUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning(
        'Failed to update stored normal category flag: $e',
        tag: 'AuthProvider',
      );
    }
  }

  Future<void> _syncVipTemplateFromStoredUser() async {
    final userJson = await _storage.read(key: _vipUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      await TemplateSessionStorage().setVipTemplateSelected(
        VipUserFields.isTemplateSelected(user),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to sync VIP template from stored user: $e',
        tag: 'AuthProvider',
      );
    }
  }

  Future<void> _syncNormalTemplateFromStoredUser() async {
    final userJson = await _storage.read(key: _normalUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      await TemplateSessionStorage().setNormalTemplateSelected(
        VipUserFields.isTemplateSelected(user),
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to sync normal template from stored user: $e',
        tag: 'AuthProvider',
      );
    }
  }

  /// Persist template selection on the stored VIP user profile.
  Future<void> updateStoredVipTemplateSelected(
    bool isSelected, {
    int? templateId,
  }) async {
    await TemplateSessionStorage().setVipTemplateSelected(isSelected);

    final userJson = await _storage.read(key: _vipUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
      user['is_template_selected'] = isSelected;
      if (templateId != null) user['template_id'] = templateId;
      await _storage.write(key: _vipUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning(
        'Failed to update stored VIP template flag: $e',
        tag: 'AuthProvider',
      );
    }
  }

  /// Persist template selection on the stored normal user profile.
  Future<void> updateStoredNormalTemplateSelected(
    bool isSelected, {
    int? templateId,
  }) async {
    await TemplateSessionStorage().setNormalTemplateSelected(isSelected);

    final userJson = await _storage.read(key: _normalUserKey);
    if (userJson == null || userJson.isEmpty) return;

    try {
      final user = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
      user['is_template_selected'] = isSelected;
      if (templateId != null) user['template_id'] = templateId;
      await _storage.write(key: _normalUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning(
        'Failed to update stored normal template flag: $e',
        tag: 'AuthProvider',
      );
    }
  }
}

class OtpActionResult {
  const OtpActionResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}