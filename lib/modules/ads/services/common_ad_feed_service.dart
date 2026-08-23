import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_exception.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/services/firebase_auth_service.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/prayer_model.dart';

class CommonAdFeedService {
  CommonAdFeedService._();

  static final CommonAdFeedService instance = CommonAdFeedService._();

  static const int defaultPerPage = 15;

  final Set<String> _recordedViewKeys = {};
  final Set<String> _pendingViewKeys = {};

  Future<String?> _resolveFirebaseUid() {
    return FirebaseAuthService.instance.ensureSignedIn();
  }

  void _registerWatchedPrayers(String feedUrl, Iterable<PrayerModel> prayers) {
    for (final prayer in prayers) {
      if (prayer.isWatched && prayer.id != null) {
        _recordedViewKeys.add('$feedUrl:${prayer.id}');
      }
    }
  }

  Future<ApiResponse<PrayersFeedResult>> fetchFeed({
    required String feedUrl,
    String status = 'active',
    int page = 1,
    int perPage = defaultPerPage,
    String? firebaseUid,
  }) async {
    final uid = firebaseUid ?? await _resolveFirebaseUid();

    AppLogger.info(
      'Fetching common ad feed url=$feedUrl page=$page perPage=$perPage status=$status',
      tag: 'CommonAdFeedService',
    );

    final response = await ApiClient.instance.get<PrayersFeedResult>(
      feedUrl,
      queryParameters: {
        'status': status,
        if (uid != null && uid.isNotEmpty) 'firebase_uid': uid,
        'page': page,
        'per_page': perPage,
      },
      parser: PrayersFeedResult.fromJson,
    );

    if (response.success) {
      final feed = response.data;
      if (feed != null) {
        _registerWatchedPrayers(feedUrl, feed.prayers);
      }
      AppLogger.success(
        'Common ad feed loaded: ${feed?.prayers.length ?? 0} '
        '(page ${feed?.currentPage}/${feed?.lastPage})',
        tag: 'CommonAdFeedService',
      );
    } else {
      AppLogger.warning(
        'Failed to load common ad feed from $feedUrl: ${response.message}',
        tag: 'CommonAdFeedService',
      );
    }

    return response;
  }

  Future<ApiResponse<bool>> recordView({
    required String viewUrl,
    required int itemId,
    String? firebaseUid,
    bool isWatched = false,
  }) async {
    final key = '$viewUrl:$itemId';
    if (isWatched || _recordedViewKeys.contains(key)) {
      AppLogger.debug(
        'Skipping view API for item $itemId at $viewUrl (already watched)',
        tag: 'CommonAdFeedService',
      );
      return ApiResponse.success(data: true, message: 'Already recorded');
    }

    if (_pendingViewKeys.contains(key)) {
      AppLogger.debug(
        'View request already in flight for item $itemId at $viewUrl',
        tag: 'CommonAdFeedService',
      );
      return ApiResponse.success(data: true, message: 'Already pending');
    }

    final uid = firebaseUid ?? await _resolveFirebaseUid();
    if (uid == null || uid.isEmpty) {
      return ApiResponse.failure(
        ApiException(message: 'Firebase UID unavailable'),
      );
    }

    _pendingViewKeys.add(key);
    AppLogger.info(
      'Recording view for item $itemId at $viewUrl',
      tag: 'CommonAdFeedService',
    );

    try {
      final response = await ApiClient.instance.post<bool>(
        viewUrl,
        data: {'firebase_uid': uid},
        parser: (_) => true,
      );

      if (response.success || response.statusCode == 409) {
        _recordedViewKeys.add(key);
        if (response.success) {
          AppLogger.success(
            'View recorded for item $itemId at $viewUrl',
            tag: 'CommonAdFeedService',
          );
        } else {
          AppLogger.debug(
            'View already recorded on server for item $itemId at $viewUrl',
            tag: 'CommonAdFeedService',
          );
        }
        return ApiResponse.success(
          data: true,
          statusCode: response.statusCode,
          message: 'Already recorded',
        );
      }

      AppLogger.warning(
        'Failed to record view for item $itemId at $viewUrl: ${response.message}',
        tag: 'CommonAdFeedService',
      );
      return response;
    } finally {
      _pendingViewKeys.remove(key);
    }
  }
}
