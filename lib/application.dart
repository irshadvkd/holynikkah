import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/provider/theme_provider.dart';
import 'package:holynikkah/core/services/navigation_logger.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:provider/provider.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  late final AppRouter _appRouter;
  final NavigationLogger _navLogger = NavigationLogger();
  final UserJourneyTracker _journeyTracker = UserJourneyTracker();

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    await _navLogger.initialize();
    // Start login journey tracking
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
            return MaterialApp.router(
              title: 'Holy Nikkah',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.currentTheme.copyWith(
                textTheme: GoogleFonts.interTextTheme(themeProvider.currentTheme.textTheme),
              ),
              routerConfig: _appRouter.config(),
              restorationScopeId: 'app',
            );
          },
        );
      },
    );
  }
}