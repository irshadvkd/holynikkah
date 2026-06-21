import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/utils/app_logger.dart';

/// Provides a stable Firebase UID for backend API calls.
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  static const _storage = FlutterSecureStorage();
  static const _uidKey = 'firebase_uid';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _cachedUid;

  /// Ensures a Firebase user exists and returns their UID.
  Future<String?> ensureSignedIn() async {
    if (_cachedUid != null && _cachedUid!.isNotEmpty) {
      return _cachedUid;
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _cachedUid = currentUser.uid;
      await _storage.write(key: _uidKey, value: _cachedUid);
      return _cachedUid;
    }

    final storedUid = await _storage.read(key: _uidKey);
    if (storedUid != null && storedUid.isNotEmpty) {
      _cachedUid = storedUid;
      return _cachedUid;
    }

    try {
      AppLogger.info('Signing in anonymously for Firebase UID', tag: 'FirebaseAuth');
      final credential = await _auth.signInAnonymously();
      _cachedUid = credential.user?.uid;
      if (_cachedUid != null) {
        await _storage.write(key: _uidKey, value: _cachedUid);
        AppLogger.success('Firebase UID ready', tag: 'FirebaseAuth');
      }
      return _cachedUid;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to obtain Firebase UID',
        tag: 'FirebaseAuth',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String? get currentUid => _auth.currentUser?.uid ?? _cachedUid;

  Future<void> signOut() async {
    await _auth.signOut();
    await _storage.delete(key: _uidKey);
    _cachedUid = null;
  }
}
