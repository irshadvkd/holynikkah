import 'package:flutter/material.dart';
import 'package:holynikkah/core/services/theme/color_service.dart';
import 'package:holynikkah/core/services/theme/text_service.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/multi_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize default theme and text styles
  await ColorService.init(mode: AppThemeMode.dark);
  await TextService.init(mode: AppThemeMode.dark);

  AppLogger.success("✅ App initialization complete", tag: "Main");

  runApp(const MultiProviderSetup());
}
