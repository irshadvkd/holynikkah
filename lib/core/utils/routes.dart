import 'package:flutter/material.dart';
import 'package:holynikkah/modules/auth/presentation/pages/fogot_password_screen.dart';
import 'package:holynikkah/modules/auth/presentation/pages/login_screen.dart';
import 'package:holynikkah/modules/auth/presentation/pages/signup_screen.dart';
import 'package:holynikkah/modules/auth/presentation/pages/splash_screen.dart';

/// 🔹 Centralized route management
class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot_password';

  /// Generate routes dynamically
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
