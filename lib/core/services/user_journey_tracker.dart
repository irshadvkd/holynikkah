import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/services/navigation_logger.dart';
import 'package:holynikkah/core/utils/app_logger.dart';

/// 📊 User Journey Tracker
/// 
/// Tracks user progress through registration and other key flows
class UserJourneyTracker {
  static final UserJourneyTracker _instance = UserJourneyTracker._internal();
  factory UserJourneyTracker() => _instance;
  UserJourneyTracker._internal();

  static const _storage = FlutterSecureStorage();
  static const String _journeyKey = 'user_journey';
  
  final NavigationLogger _navLogger = NavigationLogger();
  UserJourney? _currentJourney;

  /// Start tracking a new journey
  Future<void> startJourney(JourneyType type, {Map<String, dynamic>? context}) async {
    _currentJourney = UserJourney(
      type: type,
      startTime: DateTime.now(),
      steps: [],
      context: context ?? {},
    );

    AppLogger.info(
      'Journey started: ${type.name}',
      tag: 'UserJourney',
    );

    await _persistJourney();
  }

  /// Track a step in the current journey
  Future<void> trackStep(
    String stepName, {
    Map<String, dynamic>? data,
    bool isCompleted = true,
  }) async {
    if (_currentJourney == null) {
      AppLogger.warning('No active journey to track step: $stepName');
      return;
    }

    final step = JourneyStep(
      name: stepName,
      timestamp: DateTime.now(),
      data: data ?? {},
      isCompleted: isCompleted,
    );

    _currentJourney!.steps.add(step);

    AppLogger.info(
      'Journey step: ${_currentJourney!.type.name} → $stepName',
      tag: 'UserJourney',
    );

    await _persistJourney();
  }

  /// Complete the current journey
  Future<void> completeJourney({Map<String, dynamic>? finalData}) async {
    if (_currentJourney == null) {
      AppLogger.warning('No active journey to complete');
      return;
    }

    _currentJourney!.endTime = DateTime.now();
    _currentJourney!.isCompleted = true;
    _currentJourney!.finalData = finalData ?? {};

    final duration = _currentJourney!.duration;
    AppLogger.success(
      'Journey completed: ${_currentJourney!.type.name} in ${duration.inMinutes}m ${duration.inSeconds % 60}s',
      tag: 'UserJourney',
    );

    await _saveCompletedJourney();
    _currentJourney = null;
  }

  /// Abandon the current journey
  Future<void> abandonJourney(String reason) async {
    if (_currentJourney == null) {
      AppLogger.warning('No active journey to abandon');
      return;
    }

    _currentJourney!.endTime = DateTime.now();
    _currentJourney!.isAbandoned = true;
    _currentJourney!.abandonReason = reason;

    AppLogger.warning(
      'Journey abandoned: ${_currentJourney!.type.name} - $reason',
      tag: 'UserJourney',
    );

    await _saveCompletedJourney();
    _currentJourney = null;
  }

  /// Track registration flow specifically
  Future<void> trackRegistrationFlow({
    required bool isVip,
    required String step,
    Map<String, dynamic>? data,
  }) async {
    // Start journey if not already started
    if (_currentJourney?.type != JourneyType.registration) {
      await startJourney(
        JourneyType.registration,
        context: {'isVip': isVip},
      );
    }

    await trackStep(step, data: {'isVip': isVip, ...?data});
    
    // Also log to navigation logger
    await _navLogger.logRegistrationStep(
      step: step,
      isVip: isVip,
      data: data,
    );
  }

  /// Get current journey analytics
  JourneyAnalytics? getCurrentJourneyAnalytics() {
    if (_currentJourney == null) return null;

    return JourneyAnalytics(
      type: _currentJourney!.type,
      duration: _currentJourney!.duration,
      stepsCompleted: _currentJourney!.completedSteps.length,
      totalSteps: _currentJourney!.steps.length,
      currentStep: _currentJourney!.steps.lastOrNull?.name,
      dropOffPoints: _identifyDropOffPoints(),
    );
  }

  /// Get journey completion rate
  Future<double> getCompletionRate(JourneyType type) async {
    final journeys = await _getStoredJourneys();
    final typeJourneys = journeys.where((j) => j.type == type).toList();
    
    if (typeJourneys.isEmpty) return 0.0;
    
    final completed = typeJourneys.where((j) => j.isCompleted).length;
    return completed / typeJourneys.length;
  }

  /// Get average journey duration
  Future<Duration> getAverageDuration(JourneyType type) async {
    final journeys = await _getStoredJourneys();
    final completedJourneys = journeys
        .where((j) => j.type == type && j.isCompleted)
        .toList();
    
    if (completedJourneys.isEmpty) return Duration.zero;
    
    final totalMinutes = completedJourneys
        .map((j) => j.duration.inMinutes)
        .reduce((a, b) => a + b);
    
    return Duration(minutes: totalMinutes ~/ completedJourneys.length);
  }

  /// Get drop-off analysis
  Future<List<DropOffPoint>> getDropOffAnalysis(JourneyType type) async {
    final journeys = await _getStoredJourneys();
    final abandonedJourneys = journeys
        .where((j) => j.type == type && j.isAbandoned)
        .toList();
    
    final dropOffs = <String, int>{};
    
    for (final journey in abandonedJourneys) {
      final lastStep = journey.steps.lastOrNull?.name ?? 'start';
      dropOffs[lastStep] = (dropOffs[lastStep] ?? 0) + 1;
    }
    
    return dropOffs.entries
        .map((e) => DropOffPoint(step: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Export journey data for analysis
  Future<String> exportJourneyData() async {
    final journeys = await _getStoredJourneys();
    final current = _currentJourney;
    
    final exportData = {
      'currentJourney': current?.toJson(),
      'completedJourneys': journeys.map((j) => j.toJson()).toList(),
      'analytics': {
        'registration': {
          'completionRate': await getCompletionRate(JourneyType.registration),
          'averageDuration': (await getAverageDuration(JourneyType.registration)).inMinutes,
          'dropOffs': (await getDropOffAnalysis(JourneyType.registration))
              .map((d) => d.toJson()).toList(),
        },
      },
    };
    
    return jsonEncode(exportData);
  }

  /// Persist current journey
  Future<void> _persistJourney() async {
    if (_currentJourney == null) return;
    
    try {
      await _storage.write(
        key: _journeyKey,
        value: jsonEncode(_currentJourney!.toJson()),
      );
    } catch (e) {
      AppLogger.error('Failed to persist journey', error: e);
    }
  }

  /// Save completed journey to history
  Future<void> _saveCompletedJourney() async {
    if (_currentJourney == null) return;
    
    try {
      final journeys = await _getStoredJourneys();
      journeys.add(_currentJourney!);
      
      // Keep only last 50 journeys
      if (journeys.length > 50) {
        journeys.removeRange(0, journeys.length - 50);
      }
      
      await _storage.write(
        key: '${_journeyKey}_history',
        value: jsonEncode(journeys.map((j) => j.toJson()).toList()),
      );
      
      await _storage.delete(key: _journeyKey);
    } catch (e) {
      AppLogger.error('Failed to save completed journey', error: e);
    }
  }

  /// Get stored journeys
  Future<List<UserJourney>> _getStoredJourneys() async {
    try {
      final data = await _storage.read(key: '${_journeyKey}_history');
      if (data == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => UserJourney.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to load stored journeys', error: e);
      return [];
    }
  }

  /// Identify drop-off points in current journey
  List<String> _identifyDropOffPoints() {
    if (_currentJourney == null) return [];
    
    final dropOffs = <String>[];
    final steps = _currentJourney!.steps;
    
    for (int i = 0; i < steps.length - 1; i++) {
      final current = steps[i];
      final next = steps[i + 1];
      
      final timeDiff = next.timestamp.difference(current.timestamp);
      if (timeDiff.inMinutes > 5) {
        dropOffs.add(current.name);
      }
    }
    
    return dropOffs;
  }
}

/// User Journey Model
class UserJourney {
  final JourneyType type;
  final DateTime startTime;
  DateTime? endTime;
  final List<JourneyStep> steps;
  final Map<String, dynamic> context;
  bool isCompleted;
  bool isAbandoned;
  String? abandonReason;
  Map<String, dynamic> finalData;

  UserJourney({
    required this.type,
    required this.startTime,
    this.endTime,
    required this.steps,
    required this.context,
    this.isCompleted = false,
    this.isAbandoned = false,
    this.abandonReason,
    this.finalData = const {},
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  List<JourneyStep> get completedSteps => steps.where((s) => s.isCompleted).toList();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'steps': steps.map((s) => s.toJson()).toList(),
    'context': context,
    'isCompleted': isCompleted,
    'isAbandoned': isAbandoned,
    'abandonReason': abandonReason,
    'finalData': finalData,
  };

  factory UserJourney.fromJson(Map<String, dynamic> json) => UserJourney(
    type: JourneyType.values.firstWhere((t) => t.name == json['type']),
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    steps: (json['steps'] as List).map((s) => JourneyStep.fromJson(s)).toList(),
    context: json['context'] ?? {},
    isCompleted: json['isCompleted'] ?? false,
    isAbandoned: json['isAbandoned'] ?? false,
    abandonReason: json['abandonReason'],
    finalData: json['finalData'] ?? {},
  );
}

/// Journey Step Model
class JourneyStep {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isCompleted;

  JourneyStep({
    required this.name,
    required this.timestamp,
    required this.data,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'isCompleted': isCompleted,
  };

  factory JourneyStep.fromJson(Map<String, dynamic> json) => JourneyStep(
    name: json['name'],
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'] ?? {},
    isCompleted: json['isCompleted'] ?? false,
  );
}

/// Journey Analytics Model
class JourneyAnalytics {
  final JourneyType type;
  final Duration duration;
  final int stepsCompleted;
  final int totalSteps;
  final String? currentStep;
  final List<String> dropOffPoints;

  JourneyAnalytics({
    required this.type,
    required this.duration,
    required this.stepsCompleted,
    required this.totalSteps,
    this.currentStep,
    required this.dropOffPoints,
  });

  double get completionPercentage => 
      totalSteps > 0 ? (stepsCompleted / totalSteps) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'duration': duration.inMinutes,
    'stepsCompleted': stepsCompleted,
    'totalSteps': totalSteps,
    'currentStep': currentStep,
    'completionPercentage': completionPercentage,
    'dropOffPoints': dropOffPoints,
  };
}

/// Drop-off Point Model
class DropOffPoint {
  final String step;
  final int count;

  DropOffPoint({required this.step, required this.count});

  Map<String, dynamic> toJson() => {
    'step': step,
    'count': count,
  };
}

/// Journey Types
enum JourneyType {
  registration,
  login,
  categorySelection,
  profileSetup,
}

/// Extension for list operations
extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}