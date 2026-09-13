import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';

/// 👤 Represents authenticated Google user profile
class GoogleAuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;

  const GoogleAuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });
}

/// 📦 Data model returned by /api/verify-email
class EmailVerificationData {
  final String email;
  final bool isVipRegistered;
  final bool isNormalRegistered;
  final Map<String, dynamic>? prefillData;
  final Map<String, dynamic>? vipUser;
  final Map<String, dynamic>? normalUser;

  const EmailVerificationData({
    required this.email,
    required this.isVipRegistered,
    required this.isNormalRegistered,
    this.prefillData,
    this.vipUser,
    this.normalUser,
  });

  factory EmailVerificationData.fromJson(Map<String, dynamic> json) {
    final isVip = (json['is_vip_registered'] == true) || (json['isvipregistered'] == true);
    final isNormal = (json['is_normal_registered'] == true) || (json['isnormalregistered'] == true);

    return EmailVerificationData(
      email: json['email']?.toString() ?? '',
      isVipRegistered: isVip,
      isNormalRegistered: isNormal,
      prefillData: json['prefill_data'] as Map<String, dynamic>?,
      vipUser: json['vip_user'] as Map<String, dynamic>?,
      normalUser: json['normal_user'] as Map<String, dynamic>?,
    );
  }
}

/// 🎯 Result of Google Sign-In operation
class GoogleAuthResult {
  final bool success;
  final bool cancelled;
  final String message;
  final GoogleAuthUser? user;
  final bool isAlreadyRegistered;
  final Map<String, dynamic>? backendUserData;
  final EmailVerificationData? emailVerificationData;
  final Map<String, dynamic>? prefillData;

  const GoogleAuthResult({
    required this.success,
    this.cancelled = false,
    required this.message,
    this.user,
    this.isAlreadyRegistered = false,
    this.backendUserData,
    this.emailVerificationData,
    this.prefillData,
  });
}

/// 🔐 Service for Google Authentication (Android & iOS)
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: Platform.isIOS
        ? '269423378271-a5a4014s1ntjf5h9f8grtkbp91i4op1v.apps.googleusercontent.com'
        : null,
  );
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const _storage = FlutterSecureStorage();

  static const String keyEmail = 'google_email';
  static const String keyName = 'google_name';
  static const String keyPhoto = 'google_photo';
  static const String keyId = 'google_id';
  static const String keyIdToken = 'google_id_token';

  /// Sign in with Google on Android and iOS
  Future<GoogleAuthResult> signIn({required String type}) async {
    try {
      AppLogger.info('Starting Google Sign-In flow (type: $type)', tag: 'GoogleAuthService');

      // Clear any cached session so account picker is always displayed
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        AppLogger.info('Google Sign-In was cancelled by user', tag: 'GoogleAuthService');
        return const GoogleAuthResult(
          success: false,
          cancelled: true,
          message: 'Google Sign-In cancelled',
        );
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      // Link with Firebase Auth
      try {
        if (auth.idToken != null || auth.accessToken != null) {
          final credential = GoogleAuthProvider.credential(
            idToken: auth.idToken,
            accessToken: auth.accessToken,
          );
          await _firebaseAuth.signInWithCredential(credential);
        }
      } catch (e) {
        AppLogger.warning('Firebase link warning: $e', tag: 'GoogleAuthService');
      }

      final user = GoogleAuthUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? '',
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      // Persist in Secure Storage for registration/profile prefill
      await _storage.write(key: keyEmail, value: user.email);
      await _storage.write(key: keyName, value: user.displayName);
      if (user.photoUrl != null) {
        await _storage.write(key: keyPhoto, value: user.photoUrl);
      }
      await _storage.write(key: keyId, value: user.id);
      if (user.idToken != null) {
        await _storage.write(key: keyIdToken, value: user.idToken);
      }
      await _storage.write(key: 'registration_type', value: type);

      AppLogger.success('Google authenticated: ${user.email} (${user.displayName})', tag: 'GoogleAuthService');

      // 🔍 Call /api/verify-email API
      final verification = await verifyEmail(email: user.email);

      final isVip = type.toLowerCase() == 'vip';
      final isRegistered = isVip
          ? (verification?.isVipRegistered ?? false)
          : (verification?.isNormalRegistered ?? false);

      final backendUserData = isVip
          ? verification?.vipUser
          : verification?.normalUser;

      return GoogleAuthResult(
        success: true,
        message: isRegistered ? 'Welcome back!' : 'Google verified successfully',
        user: user,
        isAlreadyRegistered: isRegistered,
        backendUserData: backendUserData,
        emailVerificationData: verification,
        prefillData: verification?.prefillData,
      );
    } catch (e, stack) {
      AppLogger.error('Google Sign-In failed', tag: 'GoogleAuthService', error: e, stackTrace: stack);
      return const GoogleAuthResult(
        success: false,
        message: 'Google Sign-In failed. Please try again.',
      );
    }
  }

  /// 📡 Call /api/verify-email API
  Future<EmailVerificationData?> verifyEmail({required String email}) async {
    try {
      AppLogger.info('Verifying email via API: $email', tag: 'GoogleAuthService');

      final response = await ApiClient.instance.dio.post(
        AppConstants.urls.verifyEmail,
        data: {'email': email},
      );

      AppLogger.info('verify-email status: ${response.statusCode}, body: ${response.data}', tag: 'GoogleAuthService');

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final status = map['status'] == true;
        if (status && map['data'] != null && map['data'] is Map<String, dynamic>) {
          return EmailVerificationData.fromJson(map['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e, stack) {
      AppLogger.error('Failed to verify email API', tag: 'GoogleAuthService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      AppLogger.warning('Google sign out error: $e', tag: 'GoogleAuthService');
    }
  }
}
