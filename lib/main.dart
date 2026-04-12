import 'dart:io';

import 'package:flutter/material.dart';
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

void main() {
  runApp(const MultiProviderSetup());
}