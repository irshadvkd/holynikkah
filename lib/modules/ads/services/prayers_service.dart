import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_exception.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/services/firebase_auth_service.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/models/prayer_model.dart';

class PrayersService {
  PrayersService._();

  static final PrayersService instance = PrayersService._();

  static const int defaultPerPage = 10;

  final Set<int> _recordedViewIds = {};
  final Set<int> _pendingViewIds = {};

  Future<String?> _resolveFirebaseUid() {
    return FirebaseAuthService.instance.ensureSignedIn();
  }

  void _registerWatchedPrayers(Iterable<PrayerModel> prayers) {
    for (final prayer in prayers) {
      if (prayer.isWatched && prayer.id != null) {
        _recordedViewIds.add(prayer.id!);
      }
    }
  }

  Future<ApiResponse<PrayersFeedResult>> fetchFeed({
    int page = 1,
    int perPage = defaultPerPage,
    String? firebaseUid,
  }) async {
    final uid = firebaseUid ?? await _resolveFirebaseUid();
    if (uid == null || uid.isEmpty) {
      return ApiResponse.failure(
        ApiException(message: 'Firebase UID unavailable'),
      );
    }

    AppLogger.info(
      'Fetching prayers feed page=$page perPage=$perPage',
      tag: 'PrayersService',
    );

    final response = await ApiClient.instance.get<PrayersFeedResult>(
      AppConstants.urls.prayersFeed,
      queryParameters: {
        'firebase_uid': uid,
        'page': page,
        'per_page': perPage,
      },
      parser: PrayersFeedResult.fromJson,
    );

    if (response.success) {
      final feed = response.data;
      if (feed != null) {
        _registerWatchedPrayers(feed.prayers);
      }
      AppLogger.success(
        'Prayers feed loaded: ${feed?.prayers.length ?? 0} '
        '(page ${feed?.currentPage}/${feed?.lastPage})',
        tag: 'PrayersService',
      );
    } else {
      AppLogger.warning(
        'Failed to load prayers feed: ${response.message}',
        tag: 'PrayersService',
      );
    }

    return response;
  }

  Future<ApiResponse<bool>> recordView({
    required int prayerId,
    String? firebaseUid,
    bool isWatched = false,
  }) async {
    if (isWatched || _recordedViewIds.contains(prayerId)) {
      AppLogger.debug(
        'Skipping view API for prayer $prayerId (already watched)',
        tag: 'PrayersService',
      );
      return ApiResponse.success(data: true, message: 'Already recorded');
    }

    if (_pendingViewIds.contains(prayerId)) {
      AppLogger.debug(
        'View request already in flight for prayer $prayerId',
        tag: 'PrayersService',
      );
      return ApiResponse.success(data: true, message: 'Already pending');
    }

    final uid = firebaseUid ?? await _resolveFirebaseUid();
    if (uid == null || uid.isEmpty) {
      return ApiResponse.failure(
        ApiException(message: 'Firebase UID unavailable'),
      );
    }

    _pendingViewIds.add(prayerId);
    AppLogger.info('Recording view for prayer $prayerId', tag: 'PrayersService');

    try {
      final response = await ApiClient.instance.post<bool>(
        AppConstants.urls.prayersView(prayerId),
        data: {'firebase_uid': uid},
        parser: (_) => true,
      );

      if (response.success || response.statusCode == 409) {
        _recordedViewIds.add(prayerId);
        if (response.success) {
          AppLogger.success(
            'View recorded for prayer $prayerId',
            tag: 'PrayersService',
          );
        } else {
          AppLogger.debug(
            'View already recorded on server for prayer $prayerId',
            tag: 'PrayersService',
          );
        }
        return ApiResponse.success(
          data: true,
          statusCode: response.statusCode,
          message: 'Already recorded',
        );
      }

      AppLogger.warning(
        'Failed to record view for prayer $prayerId: ${response.message}',
        tag: 'PrayersService',
      );
      return response;
    } finally {
      _pendingViewIds.remove(prayerId);
    }
  }
}
