import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/partner/models/match_model.dart';

/// Read-only matrimony feed API.
///
/// `GET /normal-users/matches` → active female normal users (with a default
/// saved template, for male viewers). `GET /vip-users/matches` → active female
/// VIP users. The tier is chosen by [isVip]; the caller must have set the
/// matching bearer token first (see `AuthProvider.ensureApiTokenFor`).
class MatchesService {
  MatchesService._();

  static final MatchesService instance = MatchesService._();

  static const String _tag = 'MatchesService';
  static const int defaultPageSize = 10;

  Future<ApiResponse<MatchesFeedResult>> fetchMatches({
    required bool isVip,
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    AppLogger.info(
      'Fetching matches (vip=$isVip) page=$page pageSize=$pageSize',
      tag: _tag,
    );

    final response = await ApiClient.instance.get<MatchesFeedResult>(
      AppConstants.urls.matches(isVip),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      parser: MatchesFeedResult.fromJson,
    );

    if (response.success) {
      AppLogger.success(
        'Matches loaded: ${response.data?.matches.length ?? 0} '
        '(page ${response.data?.currentPage}/${response.data?.lastPage})',
        tag: _tag,
      );
    } else {
      AppLogger.warning(
        'Failed to load matches: ${response.message}',
        tag: _tag,
      );
    }

    return response;
  }

  /// Requests access to a match's contact info.
  ///
  /// When the backend grants access immediately it may echo the number back —
  /// the parsed [ApiResponse.data] then holds the dialable phone (else `null`,
  /// meaning the request was queued for approval). Caller must have set the
  /// matching bearer token first (see `AuthProvider.ensureApiTokenFor`).
  Future<ApiResponse<String?>> requestContactInfo({
    required bool isVip,
    required String profileId,
  }) async {
    AppLogger.info(
      'Requesting contact info (vip=$isVip) profileId=$profileId',
      tag: _tag,
    );

    final response = await ApiClient.instance.post<String?>(
      AppConstants.urls.matchContactRequest(isVip, profileId),
      parser: _parseContactPhone,
    );

    if (response.success) {
      AppLogger.success(
        'Contact request sent for profileId=$profileId '
        '(phone ${response.data == null ? 'pending' : 'granted'})',
        tag: _tag,
      );
    } else {
      AppLogger.warning(
        'Contact request failed for profileId=$profileId: ${response.message}',
        tag: _tag,
      );
    }

    return response;
  }

  static String? _parseContactPhone(dynamic json) {
    final root = json is Map ? Map<String, dynamic>.from(json) : null;
    final data = root?['data'];
    final source = data is Map
        ? Map<String, dynamic>.from(data)
        : (root ?? <String, dynamic>{});

    for (final key in const [
      'phone',
      'mobile',
      'contact',
      'contactNumber',
      'phone_number',
    ]) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }
}
