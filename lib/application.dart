import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/provider/theme_provider.dart';
import 'package:holynikkah/core/services/navigation_logger.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/navigation_analytics_widget.dart';
import 'package:holynikkah/modules/category/screens/normal_category_screen.dart';
import 'package:holynikkah/modules/category/screens/vip_category_screen.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/screens/registration_screen.dart';
import 'package:holynikkah/modules/registration/screens/verification_screen.dart';
import 'package:holynikkah/modules/splash/splash_screen.dart';
import 'package:provider/provider.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  final NavigationLogger _navLogger = NavigationLogger();
  final UserJourneyTracker _journeyTracker = UserJourneyTracker();

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    await _navLogger.initialize();
    await _journeyTracker.startJourney(JourneyType.login);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: AppConstants.misc.appName,
              debugShowCheckedModeBanner: false,
              theme: themeProvider.currentTheme.copyWith(
                textTheme: GoogleFonts.marcellusTextTheme(themeProvider.currentTheme.textTheme),
              ),
              initialRoute: Routes.splash,
              routes: {
                Routes.splash: (context) => const SplashScreen(),
                Routes.login: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return LoginScreen(type: args?['type']);
                },
                Routes.registration: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return RegistrationScreen(isVip: args?['isVip'] ?? true);
                },
                Routes.verification: (context) => const VerificationScreen(),
                Routes.categorySelection: (context) => const NormalCategoryScreen(isSelectionRequired: true),
                Routes.vipCategory: (context) => const VipCategoryScreen(isSelectionRequired: true),
                Routes.home: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return HomeScreen(initialIndex: args?['initialIndex']);
                },
                Routes.navigationAnalytics: (context) => const NavigationAnalyticsWidget(),
              },
              restorationScopeId: 'app',
            );
          },
        );
      },
    );
  }
}