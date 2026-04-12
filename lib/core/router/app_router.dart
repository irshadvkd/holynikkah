import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/widgets/navigation_analytics_widget.dart';
import 'package:holynikkah/modules/category/screens/normal_category_screen.dart';
import 'package:holynikkah/modules/category/screens/vip_category_screen.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/login/screens/forgot_password_screen.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/screens/choose_register_type.dart';
import 'package:holynikkah/modules/registration/screens/registration_screen.dart';
import 'package:holynikkah/modules/registration/screens/verification_screen.dart';
import 'package:holynikkah/modules/splash/splash_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();
  
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: ForgotPasswordRoute.page, path: '/forgot-password'),
    AutoRoute(
      page: ChooseRegisterTypeRoute.page,
      path: '/choose-register-type',
    ),
    AutoRoute(page: RegistrationRoute.page, path: '/registration'),
    AutoRoute(page: VerificationRoute.page, path: '/verification'),
    AutoRoute(page: CategorySelectionRoute.page, path: '/category-selection'),
    AutoRoute(page: VipCategoryRoute.page, path: '/vip-category'),
    AutoRoute(page: HomeRoute.page, path: '/home'),
    AutoRoute(page: NavigationAnalyticsRoute.page, path: '/navigation-analytics'),
  ];
}

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => const SplashScreen();
}

@RoutePage()
class LoginPage extends StatelessWidget {
  final String? type;
  const LoginPage({super.key, this.type});
  @override
  Widget build(BuildContext context) => LoginScreen(type: type);
}

@RoutePage()
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen();
}

@RoutePage()
class RegistrationPage extends StatelessWidget {
  final bool? isVip;
  const RegistrationPage({super.key, this.isVip});
  @override
  Widget build(BuildContext context) =>
      RegistrationScreen(isVip: isVip ?? true);
}

@RoutePage()
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});
  @override
  Widget build(BuildContext context) => const VerificationScreen();
}

@RoutePage()
class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});
  @override
  Widget build(BuildContext context) => const NormalCategoryScreen();
}

@RoutePage()
class HomePage extends StatelessWidget {
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex});
  @override
  Widget build(BuildContext context) => HomeScreen(initialIndex: initialIndex);
}

@RoutePage()
class VipCategoryPage extends StatelessWidget {
  const VipCategoryPage({super.key});
  @override
  Widget build(BuildContext context) => const VipCategoryScreen();
}

@RoutePage()
class NavigationAnalyticsPage extends StatelessWidget {
  const NavigationAnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => const NavigationAnalyticsWidget();
}
