// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CategorySelectionPage]
class CategorySelectionRoute extends PageRouteInfo<void> {
  const CategorySelectionRoute({List<PageRouteInfo>? children})
    : super(CategorySelectionRoute.name, initialChildren: children);

  static const String name = 'CategorySelectionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CategorySelectionPage();
    },
  );
}

/// generated route for
/// [ChooseRegisterTypePage]
class ChooseRegisterTypeRoute extends PageRouteInfo<void> {
  const ChooseRegisterTypeRoute({List<PageRouteInfo>? children})
    : super(ChooseRegisterTypeRoute.name, initialChildren: children);

  static const String name = 'ChooseRegisterTypeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChooseRegisterTypePage();
    },
  );
}

/// generated route for
/// [ForgotPasswordPage]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ForgotPasswordPage();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<HomeRouteArgs> {
  HomeRoute({Key? key, int? initialIndex, List<PageRouteInfo>? children})
    : super(
        HomeRoute.name,
        args: HomeRouteArgs(key: key, initialIndex: initialIndex),
        initialChildren: children,
      );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>(
        orElse: () => const HomeRouteArgs(),
      );
      return HomeScreen(key: args.key, initialIndex: args.initialIndex);
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.initialIndex});

  final Key? key;

  final int? initialIndex;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key && initialIndex == other.initialIndex;
  }

  @override
  int get hashCode => key.hashCode ^ initialIndex.hashCode;
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<LoginRouteArgs> {
  LoginRoute({Key? key, String? type, List<PageRouteInfo>? children})
    : super(
        LoginRoute.name,
        args: LoginRouteArgs(key: key, type: type),
        initialChildren: children,
      );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => const LoginRouteArgs(),
      );
      return LoginPage(key: args.key, type: args.type);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.type});

  final Key? key;

  final String? type;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && type == other.type;
  }

  @override
  int get hashCode => key.hashCode ^ type.hashCode;
}

/// generated route for
/// [NavigationAnalyticsPage]
class NavigationAnalyticsRoute extends PageRouteInfo<void> {
  const NavigationAnalyticsRoute({List<PageRouteInfo>? children})
    : super(NavigationAnalyticsRoute.name, initialChildren: children);

  static const String name = 'NavigationAnalyticsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NavigationAnalyticsPage();
    },
  );
}

/// generated route for
/// [RegistrationPage]
class RegistrationRoute extends PageRouteInfo<RegistrationRouteArgs> {
  RegistrationRoute({Key? key, bool? isVip, List<PageRouteInfo>? children})
    : super(
        RegistrationRoute.name,
        args: RegistrationRouteArgs(key: key, isVip: isVip),
        initialChildren: children,
      );

  static const String name = 'RegistrationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RegistrationRouteArgs>(
        orElse: () => const RegistrationRouteArgs(),
      );
      return RegistrationPage(key: args.key, isVip: args.isVip);
    },
  );
}

class RegistrationRouteArgs {
  const RegistrationRouteArgs({this.key, this.isVip});

  final Key? key;

  final bool? isVip;

  @override
  String toString() {
    return 'RegistrationRouteArgs{key: $key, isVip: $isVip}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RegistrationRouteArgs) return false;
    return key == other.key && isVip == other.isVip;
  }

  @override
  int get hashCode => key.hashCode ^ isVip.hashCode;
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}

/// generated route for
/// [VerificationPage]
class VerificationRoute extends PageRouteInfo<void> {
  const VerificationRoute({List<PageRouteInfo>? children})
    : super(VerificationRoute.name, initialChildren: children);

  static const String name = 'VerificationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const VerificationPage();
    },
  );
}

/// generated route for
/// [VipCategoryScreen]
class VipCategoryRoute extends PageRouteInfo<VipCategoryRouteArgs> {
  VipCategoryRoute({
    Key? key,
    dynamic Function(int)? onNavigate,
    List<PageRouteInfo>? children,
  }) : super(
         VipCategoryRoute.name,
         args: VipCategoryRouteArgs(key: key, onNavigate: onNavigate),
         initialChildren: children,
       );

  static const String name = 'VipCategoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VipCategoryRouteArgs>(
        orElse: () => const VipCategoryRouteArgs(),
      );
      return VipCategoryScreen(key: args.key, onNavigate: args.onNavigate);
    },
  );
}

class VipCategoryRouteArgs {
  const VipCategoryRouteArgs({this.key, this.onNavigate});

  final Key? key;

  final dynamic Function(int)? onNavigate;

  @override
  String toString() {
    return 'VipCategoryRouteArgs{key: $key, onNavigate: $onNavigate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VipCategoryRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}
