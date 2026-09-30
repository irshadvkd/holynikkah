import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  AppLogger.info('Handling a background message: ${message.messageId}', tag: 'FCM');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _tag = 'NotificationService';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Safely fetches the FCM token without throwing or breaking initialization
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }

    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // On iOS/macOS, APNS token must be set before getToken() can succeed.
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          // Wait briefly for APNS token generation (e.g. up to ~3 seconds)
          for (int i = 0; i < 3; i++) {
            await Future.delayed(const Duration(milliseconds: 1000));
            apnsToken = await _fcm.getAPNSToken();
            if (apnsToken != null) break;
          }
        }
        if (apnsToken == null) {
          AppLogger.warning(
            'APNS token is not available yet. FCM token retrieval deferred until APNS is registered.',
            tag: _tag,
          );
          return null;
        }
      }

      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        AppLogger.info('Device FCM Token: $_fcmToken', tag: _tag);
      }
      return _fcmToken;
    } catch (e) {
      AppLogger.warning('Could not retrieve FCM token at this time: $e', tag: _tag);
      return null;
    }
  }

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications and alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize Push & Local Notifications
  Future<void> init({Function(String token)? onTokenRefresh}) async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1. Configure iOS/macOS foreground presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Request user permissions (iOS & Android 13+) via permission_handler & FCM
      await Permission.notification.request();
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('Notification permission status: ${settings.authorizationStatus}', tag: _tag);

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Attempt initial token retrieval asynchronously without blocking init
        unawaited(() async {
          final token = await getToken();
          if (token != null && onTokenRefresh != null) {
            onTokenRefresh(token);
          }
        }());

        _fcm.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          AppLogger.info('FCM Token Refreshed: $newToken', tag: _tag);
          if (onTokenRefresh != null) {
            onTokenRefresh(newToken);
          }
        });
      }

      // 3. Initialize Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // 4. Initialize Local Notification Settings
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            AppLogger.info('Local notification tapped with payload: $payload', tag: _tag);
            try {
              final dynamic decoded = jsonDecode(payload);
              if (decoded is Map<String, dynamic>) {
                handleNotificationRouting(decoded);
              } else if (decoded is Map) {
                handleNotificationRouting(Map<String, dynamic>.from(decoded));
              }
            } catch (e) {
              AppLogger.error('Error decoding notification payload: $e', tag: _tag);
            }
          }
        },
      );

      // Check if app was launched via local notification tap
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            try {
              final dynamic decoded = jsonDecode(payload);
              if (decoded is Map<String, dynamic>) {
                handleNotificationRouting(decoded);
              }
            } catch (_) {}
          });
        }
      }

      // 5. Handle Foreground Push Messages — show local notification banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info(
          'Foreground push received: title="${message.notification?.title ?? message.data['title']}"',
          tag: _tag,
        );
        unreadCountNotifier.value += 1;
        _showLocalNotification(message);
      });

      // 6. Handle Background Push Click (when app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('Push opened from background: ${message.data}', tag: _tag);
        handleNotificationRouting(message.data);
      });

      // 7. Handle Terminated Push Click (app launch from FCM push)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App launched from push: ${initialMessage.data}', tag: _tag);
        Future.delayed(const Duration(milliseconds: 600), () {
          handleNotificationRouting(initialMessage.data);
        });
      }
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService: $e', tag: _tag);
    }
  }

  /// Displays a heads-up local notification banner for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'HolyNikah';
    final body = message.notification?.body ??
        message.data['message']?.toString() ??
        message.data['body']?.toString() ??
        '';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadString = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: payloadString,
    );
  }

  /// Helper to trigger a local heads-up notification manually
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final payloadString = data != null && data.isNotEmpty ? jsonEncode(data) : null;

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payloadString,
    );
  }

  /// Central Deep Link Handler for Push & In-App notification clicks
  void handleNotificationRouting(Map<String, dynamic> data, {BuildContext? context}) {
    final navContext = context ?? navigatorKey.currentContext;
    if (navContext == null) {
      AppLogger.warning('Cannot route notification: Navigator context is null', tag: _tag);
      return;
    }

    final type = data['type']?.toString();
    final route = data['route']?.toString();
    AppLogger.info('Routing notification type: $type, route: $route', tag: _tag);

    if (type == 'phone_request_incoming' || route == '/phone-requests/incoming') {
      Navigator.pushNamed(
        navContext,
        Routes.phoneRequests,
        arguments: {'initialIsIncoming': true},
      );
    } else if (type == 'phone_request_approved' ||
        type == 'phone_request_rejected' ||
        route == '/phone-requests/outgoing') {
      Navigator.pushNamed(
        navContext,
        Routes.phoneRequests,
        arguments: {'initialIsIncoming': false},
      );
    } else if (type == 'profile_verified' || type == 'welcome') {
      Navigator.pushNamed(navContext, Routes.home, arguments: {'initialIndex': 4});
    } else if (type == 'profile_view') {
      // Future: Navigate to specific viewer profile if viewer_id present
      Navigator.pushNamed(navContext, Routes.notifications);
    } else {
      Navigator.pushNamed(navContext, Routes.notifications);
    }
  }
}
