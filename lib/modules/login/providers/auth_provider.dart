library;

/// 🔥 AuthProvider (VIP + NORMAL - FULL CLEAN VERSION)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/services/category_session_storage.dart';
import 'package:holynikkah/core/services/crashlytics_service.dart';
import 'package:holynikkah/core/services/template_session_storage.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/services/google_auth_service.dart';
import 'package:holynikkah/core/services/notification_service.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/login/domain/auth_service.dart';
import 'package:holynikkah/modules/notifications/services/notification_api.dart';
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
  bool _isHandling401 = false;

  AuthProvider() {
    _initUnauthorizedListener();
  }

  void _initUnauthorizedListener() {
    ApiClient.instance.onUnauthorized = ({String? message}) {
      handleSessionExpired(customMessage: message);
    };
  }

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

    if (_isVipLoggedIn && token != null && token.isNotEmpty) {
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

    if (_isVipLoggedIn) {
      _syncFcmToken(isVip: true);
      NotificationApi.instance.syncUnreadCount(isVip: true);
    } else if (_isNormalLoggedIn) {
      _syncFcmToken(isVip: false);
      NotificationApi.instance.syncUnreadCount(isVip: false);
    }

    _syncCrashlyticsUserContext();

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
  /// 🔥 GOOGLE AUTH
  /// ============================

  Future<GoogleAuthResult> signInWithGoogle({required String type}) async {
    _isLoading = true;
    notifyListeners();

    AppLogger.info("Initiating Google Sign-In (type: $type)", tag: "AuthProvider");

    final result = await GoogleAuthService.instance.signIn(type: type);

    // Persist fresh tokens & user profiles for both tiers returned by verify-email
    if (result.success && result.emailVerificationData != null) {
      final verification = result.emailVerificationData!;

      if (verification.isVipRegistered && verification.vipUser != null) {
        final vipToken = verification.vipUser!['token'] as String?;
        if (vipToken != null && vipToken.isNotEmpty) {
          await _storage.write(key: _vipAuthTokenKey, value: vipToken);
          await _storage.write(key: _vipUserKey, value: jsonEncode(verification.vipUser));
        }
      }

      if (verification.isNormalRegistered && verification.normalUser != null) {
        final normalToken = verification.normalUser!['token'] as String?;
        if (normalToken != null && normalToken.isNotEmpty) {
          await _storage.write(key: _normalAuthTokenKey, value: normalToken);
          await _storage.write(key: _normalUserKey, value: jsonEncode(verification.normalUser));
        }
      }
    }

    // If user is already registered in backend, log them in for the active tier
    if (result.success && result.isAlreadyRegistered && result.backendUserData != null) {
      if (type.toLowerCase() == 'vip') {
        await setVipLoggedIn(
          token: result.backendUserData!['token'] as String?,
          user: result.backendUserData,
        );
      } else {
        await setNormalLoggedIn(
          token: result.backendUserData!['token'] as String?,
          user: result.backendUserData,
        );
      }
    }

    _isLoading = false;
    notifyListeners();

    return result;
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

    _syncFcmToken(isVip: true);
    NotificationApi.instance.syncUnreadCount(isVip: true);
    _syncCrashlyticsUserContext();

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

    _syncFcmToken(isVip: false);
    NotificationApi.instance.syncUnreadCount(isVip: false);
    _syncCrashlyticsUserContext();

    AppLogger.success("Normal user logged in", tag: "AuthProvider");

    notifyListeners();
  }

  /// 🔹 Helper to register FCM token with backend
  Future<void> _syncFcmToken({required bool isVip}) async {
    final fcmToken = await NotificationService.instance.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await NotificationApi.instance.registerDeviceToken(
        isVip: isVip,
        fcmToken: fcmToken,
      );
    }
  }

  /// ============================
  /// 🔥 LOGOUT METHODS
  /// ============================

  /// 🔹 LOGOUT VIP ONLY
  Future<void> logoutVip() async {
    AppLogger.info("Logging out VIP...", tag: "AuthProvider");

    NotificationApi.instance.removeDeviceToken(isVip: true);

    _isVipLoggedIn = false;

    await _storage.delete(key: _vipLoginKey);
    await _storage.delete(key: _vipAuthTokenKey);
    await _storage.delete(key: _vipUserKey);
    await CategorySessionStorage().setVipCategorySelected(false);
    await TemplateSessionStorage().setVipTemplateSelected(false);

    if (_isNormalLoggedIn) {
      final normalToken = await _storage.read(key: _normalAuthTokenKey);
      ApiClient.instance.setAuthToken(normalToken);
      NotificationApi.instance.syncUnreadCount(isVip: false);
    } else {
      ApiClient.instance.setAuthToken(null);
      NotificationService.instance.unreadCountNotifier.value = 0;
    }

    _syncCrashlyticsUserContext();

    notifyListeners();
  }

  /// 🔹 LOGOUT NORMAL ONLY
  Future<void> logoutNormal() async {
    AppLogger.info("Logging out NORMAL...", tag: "AuthProvider");

    NotificationApi.instance.removeDeviceToken(isVip: false);

    _isNormalLoggedIn = false;

    await _storage.delete(key: _normalLoginKey);
    await _storage.delete(key: _normalAuthTokenKey);
    await _storage.delete(key: _normalUserKey);
    await CategorySessionStorage().setNormalCategorySelected(false);
    await TemplateSessionStorage().setNormalTemplateSelected(false);

    if (_isVipLoggedIn) {
      final vipToken = await _storage.read(key: _vipAuthTokenKey);
      ApiClient.instance.setAuthToken(vipToken);
      NotificationApi.instance.syncUnreadCount(isVip: true);
    } else {
      ApiClient.instance.setAuthToken(null);
      NotificationService.instance.unreadCountNotifier.value = 0;
    }

    _syncCrashlyticsUserContext();

    notifyListeners();
  }

  /// 🔹 LOGOUT ALL
  Future<void> logoutAll() async {
    AppLogger.info("Logging out ALL users...", tag: "AuthProvider");

    NotificationApi.instance.removeDeviceToken(isVip: true);
    NotificationApi.instance.removeDeviceToken(isVip: false);

    await AuthService.instance.logout();

    _isVipLoggedIn = false;
    _isNormalLoggedIn = false;

    await _storage.delete(key: _vipLoginKey);
    await _storage.delete(key: _vipAuthTokenKey);
    await _storage.delete(key: _vipUserKey);
    await _storage.delete(key: _normalLoginKey);
    await _storage.delete(key: _normalAuthTokenKey);
    await _storage.delete(key: _normalUserKey);
    ApiClient.instance.setAuthToken(null);
    NotificationService.instance.unreadCountNotifier.value = 0;
    await CategorySessionStorage().setVipCategorySelected(false);
    await CategorySessionStorage().setNormalCategorySelected(false);
    await TemplateSessionStorage().clearAllTemplateSelections();

    AppLogger.success("All users logged out", tag: "AuthProvider");

    _syncCrashlyticsUserContext();

    notifyListeners();
  }

  /// 🔹 Handle 401 Unauthorized (e.g. session expired or logged in on another device)
  Future<void> handleSessionExpired({String? customMessage}) async {
    if (!_isVipLoggedIn && !_isNormalLoggedIn) return;
    if (_isHandling401) return;
    _isHandling401 = true;

    AppLogger.warning(
      "Session expired / logged in on another device (401). Clearing local session...",
      tag: "AuthProvider",
    );

    _isVipLoggedIn = false;
    _isNormalLoggedIn = false;
    ApiClient.instance.setAuthToken(null);

    await _storage.delete(key: _vipLoginKey);
    await _storage.delete(key: _vipAuthTokenKey);
    await _storage.delete(key: _vipUserKey);
    await _storage.delete(key: _normalLoginKey);
    await _storage.delete(key: _normalAuthTokenKey);
    await _storage.delete(key: _normalUserKey);
    await CategorySessionStorage().setVipCategorySelected(false);
    await CategorySessionStorage().setNormalCategorySelected(false);
    await TemplateSessionStorage().clearAllTemplateSelections();

    _syncCrashlyticsUserContext();

    notifyListeners();

    final navContext = NotificationService.instance.navigatorKey.currentContext;
    if (navContext != null) {
      Navigator.of(navContext).pushNamedAndRemoveUntil(
        Routes.home,
        (route) => false,
      );

      final displayMsg = (customMessage != null && customMessage.isNotEmpty)
          ? customMessage
          : 'Your session has expired. You may have logged in from another device.';

      CommonSnackBar.show(
        navContext,
        message: displayMsg,
        type: SnackBarType.warning,
      );
    }

    Future.delayed(const Duration(seconds: 3), () {
      _isHandling401 = false;
    });
  }

  /// ============================
  /// 🔥 ACCOUNT DELETION
  /// ============================

  /// Permanently deletes the account on backend and clears local session
  Future<ApiResponse<dynamic>> deleteAccount({required bool isVip}) async {
    AppLogger.info(
      "Requesting account deletion for ${isVip ? 'VIP' : 'NORMAL'} user...",
      tag: "AuthProvider",
    );

    await ensureApiTokenFor(isVip: isVip);

    final path = AppConstants.urls.deleteAccount(isVip);
    final response = await ApiClient.instance.delete<dynamic>(
      path,
      parser: (json) => json,
    );

    if (response.success) {
      AppLogger.success(
        "Account deleted successfully on backend (${isVip ? 'VIP' : 'NORMAL'})",
        tag: "AuthProvider",
      );

      if (isVip) {
        await logoutVip();
      } else {
        await logoutNormal();
      }
    } else {
      AppLogger.warning(
        "Failed to delete ${isVip ? 'VIP' : 'NORMAL'} account: ${response.message} (status: ${response.statusCode})",
        tag: "AuthProvider",
      );
    }

    return response;
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
    var token = await _storage.read(key: key);

    // Auto-recovery: If token is missing, attempt to retrieve token via verifyEmail
    if (token == null || token.isEmpty) {
      final user = await getStoredUser(isVip: isVip);
      final email = user?['email']?.toString() ??
          await _storage.read(key: GoogleAuthService.keyEmail);
      if (email != null && email.isNotEmpty) {
        try {
          final res =
              await GoogleAuthService.instance.verifyEmail(email: email);
          if (res != null) {
            if (res.isVipRegistered && res.vipUser != null) {
              final freshVipToken = res.vipUser!['token']?.toString();
              if (freshVipToken != null && freshVipToken.isNotEmpty) {
                await _storage.write(key: _vipAuthTokenKey, value: freshVipToken);
                await updateStoredVipUser(res.vipUser!);
                if (isVip) token = freshVipToken;
              }
            }
            if (res.isNormalRegistered && res.normalUser != null) {
              final freshNormalToken = res.normalUser!['token']?.toString();
              if (freshNormalToken != null && freshNormalToken.isNotEmpty) {
                await _storage.write(key: _normalAuthTokenKey, value: freshNormalToken);
                await updateStoredNormalUser(res.normalUser!);
                if (!isVip) token = freshNormalToken;
              }
            }
          }
        } catch (e) {
          AppLogger.warning('Token auto-recovery failed: $e', tag: 'AuthProvider');
        }
      }
    }

    ApiClient.instance.setAuthToken(token);
  }

  /// 🔹 Get stored user map for VIP or Normal
  Future<Map<String, dynamic>?> getStoredUser({required bool isVip}) async {
    final key = isVip ? _vipUserKey : _normalUserKey;
    final userJson = await _storage.read(key: key);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(userJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e) {
      AppLogger.warning('Failed to parse stored user ($key): $e', tag: 'AuthProvider');
      return null;
    }
  }

  /// 🔹 Update full stored VIP user data
  Future<void> updateStoredVipUser(Map<String, dynamic> user) async {
    try {
      await _storage.write(key: _vipUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning('Failed to update stored VIP user: $e', tag: 'AuthProvider');
    }
  }

  /// 🔹 Update full stored Normal user data
  Future<void> updateStoredNormalUser(Map<String, dynamic> user) async {
    try {
      await _storage.write(key: _normalUserKey, value: jsonEncode(user));
    } catch (e) {
      AppLogger.warning('Failed to update stored normal user: $e', tag: 'AuthProvider');
    }
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

  /// 🔹 Sync User Context & Custom Attributes with Crashlytics
  Future<void> _syncCrashlyticsUserContext() async {
    try {
      CrashlyticsService.instance.setCustomKey('is_vip_logged_in', _isVipLoggedIn);
      CrashlyticsService.instance.setCustomKey('is_normal_logged_in', _isNormalLoggedIn);

      if (_isVipLoggedIn) {
        final user = await getStoredUser(isVip: true);
        final id = user?['id']?.toString() ?? user?['user_id']?.toString() ?? user?['phone']?.toString();
        if (id != null && id.isNotEmpty) {
          await CrashlyticsService.instance.setUserIdentifier('VIP_$id');
        }
      } else if (_isNormalLoggedIn) {
        final user = await getStoredUser(isVip: false);
        final id = user?['id']?.toString() ?? user?['user_id']?.toString() ?? user?['phone']?.toString();
        if (id != null && id.isNotEmpty) {
          await CrashlyticsService.instance.setUserIdentifier('NORMAL_$id');
        }
      } else {
        await CrashlyticsService.instance.clearUserIdentifier();
      }
    } catch (e) {
      AppLogger.warning('Failed to sync Crashlytics user context: $e', tag: 'AuthProvider');
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