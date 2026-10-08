import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/services/crashlytics_service.dart';
import 'package:holynikkah/core/services/firebase_auth_service.dart';
import 'package:holynikkah/core/services/notification_service.dart';
import 'package:holynikkah/core/services/screen_security_service.dart';
import 'package:holynikkah/firebase_options.dart';
import 'package:holynikkah/multi_provider.dart';

/// ----------------------
/// HTTP override for certificates
/// ----------------------
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashlyticsService.instance.init();

  // 🛡️ Catch and report all Flutter framework fatal and UI rendering errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashlyticsService.instance.recordFlutterError(details);
  };

  // 🛡️ Catch and report all uncaught asynchronous Dart isolate errors
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashlyticsService.instance.recordError(error, stack, fatal: true);
    return true;
  };


  await FirebaseAuthService.instance.ensureSignedIn();
  ApiClient.instance.init();
  await NotificationService.instance.init();
  await ScreenSecurityService.instance.init();
  runApp(const MultiProviderSetup());
}