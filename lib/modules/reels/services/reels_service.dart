import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_exception.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/services/firebase_auth_service.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/models/video_model.dart';

class ReelsService {
  ReelsService._();

  static final ReelsService instance = ReelsService._();

  static const int defaultPerPage = 10;

  final Set<int> _recordedViewIds = {};
  final Set<int> _pendingViewIds = {};

  Future<String?> _resolveFirebaseUid() {
    return FirebaseAuthService.instance.ensureSignedIn();
  }

  void _registerWatchedReels(Iterable<VideoModel> reels) {
    for (final reel in reels) {
      if (reel.isWatched && reel.id != null) {
        _recordedViewIds.add(reel.id!);
      }
    }
  }

  Future<ApiResponse<ReelsFeedResult>> fetchFeed({
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
      'Fetching reels feed page=$page perPage=$perPage',
      tag: 'ReelsService',
    );

    final response = await ApiClient.instance.get<ReelsFeedResult>(
      AppConstants.urls.reelsFeed,
      queryParameters: {
        'firebase_uid': uid,
        'page': page,
        'per_page': perPage,
      },
      parser: ReelsFeedResult.fromJson,
    );

    if (response.success) {
      final feed = response.data;
      if (feed != null) {
        _registerWatchedReels(feed.reels);
      }
      AppLogger.success(
        'Reels feed loaded: ${feed?.reels.length ?? 0} '
        '(page ${feed?.currentPage}/${feed?.lastPage})',
        tag: 'ReelsService',
      );
    } else {
      AppLogger.warning(
        'Failed to load reels feed: ${response.message}',
        tag: 'ReelsService',
      );
    }

    return response;
  }

  Future<ApiResponse<bool>> recordView({
    required int reelId,
    String? firebaseUid,
    bool isWatched = false,
  }) async {
    if (isWatched || _recordedViewIds.contains(reelId)) {
      AppLogger.debug(
        'Skipping view API for reel $reelId (already watched)',
        tag: 'ReelsService',
      );
      return ApiResponse.success(data: true, message: 'Already recorded');
    }

    if (_pendingViewIds.contains(reelId)) {
      AppLogger.debug(
        'View request already in flight for reel $reelId',
        tag: 'ReelsService',
      );
      return ApiResponse.success(data: true, message: 'Already pending');
    }

    final uid = firebaseUid ?? await _resolveFirebaseUid();
    if (uid == null || uid.isEmpty) {
      return ApiResponse.failure(
        ApiException(message: 'Firebase UID unavailable'),
      );
    }

    _pendingViewIds.add(reelId);
    AppLogger.info('Recording view for reel $reelId', tag: 'ReelsService');

    try {
      final response = await ApiClient.instance.post<bool>(
        AppConstants.urls.reelsView(reelId),
        data: {'firebase_uid': uid},
        parser: (_) => true,
      );

      if (response.success || response.statusCode == 409) {
        _recordedViewIds.add(reelId);
        if (response.success) {
          AppLogger.success('View recorded for reel $reelId', tag: 'ReelsService');
        } else {
          AppLogger.debug(
            'View already recorded on server for reel $reelId',
            tag: 'ReelsService',
          );
        }
        return ApiResponse.success(
          data: true,
          statusCode: response.statusCode,
          message: 'Already recorded',
        );
      }

      AppLogger.warning(
        'Failed to record view for reel $reelId: ${response.message}',
        tag: 'ReelsService',
      );
      return response;
    } finally {
      _pendingViewIds.remove(reelId);
    }
  }
}
