import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _creamDim = Color(0xFFDCD4C0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AppLogger.info("Splash screens initializing...", tag: "SplashScreen");
    await Future.delayed(const Duration(seconds: 2));
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

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.darkGreenGradient,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppConstants.icons.logoVertical,
                  width: 220.w,
                  height: 220.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 18.h),
                Text(
                  'Great people find sacred souls',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    color: _creamDim,
                    fontSize: 18.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
