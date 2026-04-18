import 'package:flutter/material.dart';
import 'package:holynikkah/core/services/navigation_logger.dart';
import 'package:holynikkah/core/utils/app_logger.dart';

/// 🛡️ Navigation Guard
/// 
/// Prevents duplicate navigation, handles errors, and ensures safe navigation
class NavigationGuard {
  static final NavigationGuard _instance = NavigationGuard._internal();
  factory NavigationGuard() => _instance;
  NavigationGuard._internal();

  final NavigationLogger _logger = NavigationLogger();
  String? _lastRoute;
  DateTime? _lastNavigationTime;
  bool _isNavigating = false;

  /// Safe navigation with duplicate prevention
  Future<bool> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool replaceAll = false,
    String? trigger,
    Map<String, dynamic>? data,
  }) async {
    if (!context.mounted) {
      AppLogger.warning('Context not mounted, navigation cancelled');
      return false;
    }

    final currentTime = DateTime.now();

    // Prevent duplicate navigation
    if (_isDuplicateNavigation(routeName, currentTime)) {
      AppLogger.warning(
        'Duplicate navigation prevented: $routeName',
        tag: 'NavigationGuard',
      );
      return false;
    }

    // Prevent navigation while already navigating
    if (_isNavigating) {
      AppLogger.warning(
        'Navigation in progress, request ignored: $routeName',
        tag: 'NavigationGuard',
      );
      return false;
    }

    try {
      _isNavigating = true;
      final currentRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';

      // Log navigation attempt
      await _logger.logRouteChange(
        from: currentRoute,
        to: routeName,
        parameters: {
          if (arguments != null) 'args': arguments,
          ...?data,
        },
        trigger: trigger,
      );

      // Perform navigation
      bool success = false;
      if (replaceAll) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
        success = true;
      } else if (replace) {
        Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
        success = true;
      } else {
        Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
        success = true;
      }

      if (success) {
        _lastRoute = routeName;
        _lastNavigationTime = currentTime;
        
        AppLogger.success(
          'Navigation successful: $currentRoute → $routeName',
          tag: 'NavigationGuard',
        );
      }

      return success;
    } catch (e, stackTrace) {
      await _logger.logNavigationError(
        route: routeName,
        error: e.toString(),
        context: {'trigger': trigger, 'data': data},
      );

      AppLogger.error(
        'Navigation failed: $routeName',
        error: e,
        stackTrace: stackTrace,
        tag: 'NavigationGuard',
      );

      return false;
    } finally {
      _isNavigating = false;
    }
  }

  /// Safe pop with logging
  Future<bool> pop(BuildContext context, {dynamic result}) async {
    if (!context.mounted) {
      AppLogger.warning('Context not mounted, pop cancelled');
      return false;
    }

    try {
      final currentRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';
      final canPop = Navigator.of(context).canPop();

      if (!canPop) {
        AppLogger.warning('Cannot pop from $currentRoute');
        return false;
      }

      Navigator.of(context).pop(result);
      
      await _logger.logRouteChange(
        from: currentRoute,
        to: 'previous',
        trigger: 'pop',
      );

      AppLogger.info('Pop successful from $currentRoute', tag: 'NavigationGuard');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Pop failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'NavigationGuard',
      );
      return false;
    }
  }

  /// Navigate with validation
  Future<bool> navigateWithValidation(
    BuildContext context,
    String routeName, {
    Object? arguments,
    required bool Function() validator,
    String? validationError,
    bool replace = false,
    String? trigger,
  }) async {
    if (!validator()) {
      final error =
          validationError ?? 'Validation failed for $routeName';
      AppLogger.warning(error, tag: 'NavigationGuard');
      
      await _logger.logNavigationError(
        route: routeName,
        error: error,
        context: {'trigger': trigger},
      );
      
      return false;
    }

    return navigateTo(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      trigger: trigger,
    );
  }

  /// Check if navigation is duplicate
  bool _isDuplicateNavigation(String routeName, DateTime currentTime) {
    if (_lastRoute != routeName) return false;
    if (_lastNavigationTime == null) return false;
    
    final timeDiff = currentTime.difference(_lastNavigationTime!);
    return timeDiff.inMilliseconds < 1000; // Prevent navigation within 1 second
  }

  /// Reset navigation state
  void reset() {
    _lastRoute = null;
    _lastNavigationTime = null;
    _isNavigating = false;
    AppLogger.info('Navigation guard reset', tag: 'NavigationGuard');
  }

  /// Get navigation status
  NavigationStatus getStatus() {
    return NavigationStatus(
      isNavigating: _isNavigating,
      lastRoute: _lastRoute,
      lastNavigationTime: _lastNavigationTime,
    );
  }
}

/// Navigation Status Model
class NavigationStatus {
  final bool isNavigating;
  final String? lastRoute;
  final DateTime? lastNavigationTime;

  NavigationStatus({
    required this.isNavigating,
    this.lastRoute,
    this.lastNavigationTime,
  });

  Map<String, dynamic> toJson() => {
    'isNavigating': isNavigating,
    'lastRoute': lastRoute,
    'lastNavigationTime': lastNavigationTime?.toIso8601String(),
  };
}

/// Extension for easy access to NavigationGuard
extension NavigationGuardExtension on BuildContext {
  NavigationGuard get navigationGuard => NavigationGuard();
}