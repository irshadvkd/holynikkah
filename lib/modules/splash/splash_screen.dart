import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/widgets/logo_widget.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AppLogger.info("Splash screens initializing...", tag: "SplashScreen");
    final delay = kDebugMode ? Duration.zero : const Duration(seconds: 2);
    await Future.delayed(delay);
    if (!mounted) return;

    AppLogger.info("Checking login status...", tag: "SplashScreen");
    await context.read<AuthProvider>().checkLoginStatus();
    if (!mounted) return;

    await context.read<CategoryProvider>().loadCategory();
    if (!mounted) return;

    final isVipLoggedIn = context.read<AuthProvider>().isVipLoggedIn;
    final isNormalLoggedIn = context.read<AuthProvider>().isNormalLoggedIn;
    AppLogger.info("Vip Login status: $isVipLoggedIn", tag: "SplashScreen");
    AppLogger.info("Normal Login status: $isNormalLoggedIn", tag: "SplashScreen");
    AppLogger.info("Navigating to HomeRoute...", tag: "SplashScreen");
    // await context.read<AuthProvider>().clearAuthData();

    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: const LogoWidget(size: 300)));
  }
}
