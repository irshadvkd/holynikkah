import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/provider/theme_provider.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:provider/provider.dart';

/// 🔹 Root widget of the app
class Application extends StatelessWidget {
  const Application({super.key});

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
              debugShowCheckedModeBanner: false,
              title: "Holy Nikkah",
              theme: themeProvider.lightThemeData,
              darkTheme: themeProvider.darkThemeData,
              themeMode: themeProvider.isDark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              initialRoute: Routes.splash,
              onGenerateRoute: Routes.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
