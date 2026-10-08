import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/services/crashlytics_service.dart';
import 'package:holynikkah/core/utils/app_logger.dart';

/// 🧭 Navigation Logger Service
/// 
/// Tracks user navigation patterns, identifies issues, and provides analytics
class NavigationLogger {
  static final NavigationLogger _instance = NavigationLogger._internal();
  factory NavigationLogger() => _instance;
  NavigationLogger._internal();

  static const _storage = FlutterSecureStorage();
  static const String _sessionKey = 'current_session';
  
  final List<NavigationEvent> _currentSession = [];
  String? _currentRoute;
  DateTime? _sessionStart;

  /// Initialize navigation tracking
  Future<void> initialize() async {
    _sessionStart = DateTime.now();
    AppLogger.info('Navigation tracking initialized', tag: 'Navigation');
  }

  /// Log route change
  Future<void> logRouteChange({
    required String from,
    required String to,
    Map<String, dynamic>? parameters,
    String? trigger,
  }) async {
    final event = NavigationEvent(
      from: from,
      to: to,
      timestamp: DateTime.now(),
      parameters: parameters,
      trigger: trigger ?? 'unknown',
    );

    _currentSession.add(event);
    _currentRoute = to;
    CrashlyticsService.instance.setCustomKey('current_screen', to);

    AppLogger.info(
      'Route: $from → $to ${parameters != null ? 'with params: $parameters' : ''}',
      tag: 'Navigation',
    );

    await _persistSession();
  }

  /// Log navigation error
  Future<void> logNavigationError({
    required String route,
    required String error,
    Map<String, dynamic>? context,
  }) async {
    final event = NavigationEvent(
      from: _currentRoute ?? 'unknown',
      to: route,
      timestamp: DateTime.now(),
      error: error,
      parameters: context,
      trigger: 'error',
    );

    _currentSession.add(event);

    AppLogger.error(
      'Navigation Error: $error on route $route',
      tag: 'Navigation',
    );

    await _persistSession();
  }

  /// Log user action that triggers navigation
  Future<void> logUserAction({
    required String action,
    required String route,
    Map<String, dynamic>? data,
  }) async {
    AppLogger.debug(
      'User Action: $action on $route ${data != null ? 'with data: $data' : ''}',
      tag: 'UserAction',
    );
  }

  /// Track registration flow progress
  Future<void> logRegistrationStep({
    required String step,
    required bool isVip,
    Map<String, dynamic>? data,
  }) async {
    final event = NavigationEvent(
      from: _currentRoute ?? 'unknown',
      to: 'registration_$step',
      timestamp: DateTime.now(),
      parameters: {'isVip': isVip, ...?data},
      trigger: 'registration_flow',
    );

    _currentSession.add(event);

    AppLogger.info(
      'Registration Step: $step (${isVip ? 'VIP' : 'Normal'})',
      tag: 'Registration',
    );

    await _persistSession();
  }

  /// Get current session analytics
  NavigationAnalytics getSessionAnalytics() {
    if (_sessionStart == null) return NavigationAnalytics.empty();

    final duration = DateTime.now().difference(_sessionStart!);
    final routes = _currentSession.map((e) => e.to).toSet().toList();
    final errors = _currentSession.where((e) => e.error != null).toList();
    
    return NavigationAnalytics(
      sessionDuration: duration,
      routesVisited: routes,
      totalNavigations: _currentSession.length,
      errors: errors,
      registrationSteps: _getRegistrationSteps(),
    );
  }

  /// Get navigation history for debugging
  List<NavigationEvent> getNavigationHistory() => List.from(_currentSession);

  /// Check for potential navigation issues
  List<NavigationIssue> detectIssues() {
    final issues = <NavigationIssue>[];

    // Detect duplicate navigations
    for (int i = 0; i < _currentSession.length - 1; i++) {
      final current = _currentSession[i];
      final next = _currentSession[i + 1];
      
      if (current.to == next.to && 
          next.timestamp.difference(current.timestamp).inMilliseconds < 1000) {
        issues.add(NavigationIssue(
          type: NavigationIssueType.duplicateNavigation,
          route: current.to,
          timestamp: current.timestamp,
          description: 'Duplicate navigation to ${current.to} within 1 second',
        ));
      }
    }

    // Detect rapid back-and-forth navigation
    for (int i = 0; i < _currentSession.length - 2; i++) {
      final first = _currentSession[i];
      final second = _currentSession[i + 1];
      final third = _currentSession[i + 2];
      
      if (first.to == third.to && first.to != second.to) {
        issues.add(NavigationIssue(
          type: NavigationIssueType.rapidBackAndForth,
          route: first.to,
          timestamp: first.timestamp,
          description: 'Rapid back-and-forth between ${first.to} and ${second.to}',
        ));
      }
    }

    // Detect registration flow issues
    final regSteps = _getRegistrationSteps();
    if (regSteps.length > 1) {
      for (int i = 0; i < regSteps.length - 1; i++) {
        final current = regSteps[i];
        final next = regSteps[i + 1];
        
        if (next.timestamp.difference(current.timestamp).inMinutes > 10) {
          issues.add(NavigationIssue(
            type: NavigationIssueType.longRegistrationGap,
            route: current.to,
            timestamp: current.timestamp,
            description: 'Long gap (${next.timestamp.difference(current.timestamp).inMinutes} min) in registration flow',
          ));
        }
      }
    }

    return issues;
  }

  /// Clear current session
  Future<void> clearSession() async {
    _currentSession.clear();
    _currentRoute = null;
    _sessionStart = DateTime.now();
    await _storage.delete(key: _sessionKey);
    AppLogger.info('Navigation session cleared', tag: 'Navigation');
  }

  /// Persist session data
  Future<void> _persistSession() async {
    try {
      final sessionData = {
        'start': _sessionStart?.toIso8601String(),
        'events': _currentSession.map((e) => e.toJson()).toList(),
        'currentRoute': _currentRoute,
      };
      
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(sessionData),
      );
    } catch (e) {
      AppLogger.error('Failed to persist navigation session', error: e);
    }
  }

  /// Get registration steps from current session
  List<NavigationEvent> _getRegistrationSteps() {
    return _currentSession
        .where((e) => e.trigger == 'registration_flow')
        .toList();
  }

  /// Export session data for analysis
  Future<String> exportSessionData() async {
    final analytics = getSessionAnalytics();
    final issues = detectIssues();
    
    final exportData = {
      'session': {
        'start': _sessionStart?.toIso8601String(),
        'duration': analytics.sessionDuration.inMinutes,
        'routes': analytics.routesVisited,
        'navigations': analytics.totalNavigations,
      },
      'events': _currentSession.map((e) => e.toJson()).toList(),
      'issues': issues.map((i) => i.toJson()).toList(),
      'analytics': analytics.toJson(),
    };
    
    return jsonEncode(exportData);
  }
}

/// Navigation Event Model
class NavigationEvent {
  final String from;
  final String to;
  final DateTime timestamp;
  final Map<String, dynamic>? parameters;
  final String trigger;
  final String? error;

  NavigationEvent({
    required this.from,
    required this.to,
    required this.timestamp,
    this.parameters,
    required this.trigger,
    this.error,
  });

  static Object? _jsonSafe(Object? value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();

    if (value is List) {
      return value.map((e) => _jsonSafe(e)).toList();
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _jsonSafe(v)));
    }

    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'timestamp': timestamp.toIso8601String(),
    'parameters': _jsonSafe(parameters),
    'trigger': trigger,
    'error': error,
  };

  factory NavigationEvent.fromJson(Map<String, dynamic> json) => NavigationEvent(
    from: json['from'],
    to: json['to'],
    timestamp: DateTime.parse(json['timestamp']),
    parameters: json['parameters'],
    trigger: json['trigger'],
    error: json['error'],
  );
}

/// Navigation Analytics Model
class NavigationAnalytics {
  final Duration sessionDuration;
  final List<String> routesVisited;
  final int totalNavigations;
  final List<NavigationEvent> errors;
  final List<NavigationEvent> registrationSteps;

  NavigationAnalytics({
    required this.sessionDuration,
    required this.routesVisited,
    required this.totalNavigations,
    required this.errors,
    required this.registrationSteps,
  });

  factory NavigationAnalytics.empty() => NavigationAnalytics(
    sessionDuration: Duration.zero,
    routesVisited: [],
    totalNavigations: 0,
    errors: [],
    registrationSteps: [],
  );

  Map<String, dynamic> toJson() => {
    'sessionDuration': sessionDuration.inMinutes,
    'routesVisited': routesVisited,
    'totalNavigations': totalNavigations,
    'errorCount': errors.length,
    'registrationStepsCount': registrationSteps.length,
  };
}

/// Navigation Issue Model
class NavigationIssue {
  final NavigationIssueType type;
  final String route;
  final DateTime timestamp;
  final String description;

  NavigationIssue({
    required this.type,
    required this.route,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'route': route,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };
}

/// Navigation Issue Types
enum NavigationIssueType {
  duplicateNavigation,
  rapidBackAndForth,
  longRegistrationGap,
  navigationError,
  unexpectedRoute,
}