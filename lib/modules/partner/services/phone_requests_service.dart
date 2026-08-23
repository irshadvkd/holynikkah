import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/partner/models/phone_request_model.dart';

/// Phone-visibility request API (the four-step approval flow).
///
/// 1. [createRequest] — requester asks for a hidden profile's phone.
/// 2. [fetchIncoming] — target lists requests made to them.
/// 3. [respond] — target approves/rejects a request.
/// 4. [fetchOutgoing] — requester lists their requests (approved reveal phone).
///
/// The tier is chosen by `isVip`; the caller must have set the matching bearer
/// token first (see `AuthProvider.ensureApiTokenFor`).
class PhoneRequestsService {
  PhoneRequestsService._();

  static final PhoneRequestsService instance = PhoneRequestsService._();

  static const String _tag = 'PhoneRequestsService';
  static const int defaultPageSize = 10;

  /// Step 1 — POST `/{tier}-users/phone-requests` with `{ "target_id": id }`.
  ///
  /// Returns the revealed phone in [ApiResponse.data] if the backend grants it
  /// immediately, otherwise `null` (request queued for approval).
  Future<ApiResponse<String?>> createRequest({
    required bool isVip,
    required int targetId,
  }) async {
    AppLogger.info(
      'Creating phone request (vip=$isVip) targetId=$targetId',
      tag: _tag,
    );

    final response = await ApiClient.instance.post<String?>(
      AppConstants.urls.phoneRequests(isVip),
      data: {'target_id': targetId},
      parser: _parsePhone,
    );

    if (response.success) {
      AppLogger.success(
        'Phone request created for targetId=$targetId '
        '(phone ${response.data == null ? 'pending' : 'granted'})',
        tag: _tag,
      );
    } else {
      AppLogger.warning(
        'Phone request failed for targetId=$targetId: ${response.message}',
        tag: _tag,
      );
    }

    return response;
  }

  /// Step 2 — GET `/{tier}-users/phone-requests/incoming`.
  Future<ApiResponse<PhoneRequestsResult>> fetchIncoming({
    required bool isVip,
    String? status,
    int page = 1,
    int pageSize = defaultPageSize,
  }) {
    return _fetchList(
      isVip: isVip,
      path: AppConstants.urls.phoneRequestsIncoming(isVip),
      status: status,
      page: page,
      pageSize: pageSize,
      label: 'incoming',
    );
  }

  /// Step 4 — GET `/{tier}-users/phone-requests/outgoing`.
  Future<ApiResponse<PhoneRequestsResult>> fetchOutgoing({
    required bool isVip,
    String? status,
    int page = 1,
    int pageSize = defaultPageSize,
  }) {
    return _fetchList(
      isVip: isVip,
      path: AppConstants.urls.phoneRequestsOutgoing(isVip),
      status: status,
      page: page,
      pageSize: pageSize,
      label: 'outgoing',
    );
  }

  Future<ApiResponse<PhoneRequestsResult>> _fetchList({
    required bool isVip,
    required String path,
    required String label,
    String? status,
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    AppLogger.info(
      'Fetching $label phone requests (vip=$isVip) '
      'status=${status ?? 'any'} page=$page',
      tag: _tag,
    );

    final response = await ApiClient.instance.get<PhoneRequestsResult>(
      path,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
      parser: PhoneRequestsResult.fromJson,
    );

    if (response.success) {
      AppLogger.success(
        '$label phone requests loaded: ${response.data?.requests.length ?? 0}',
        tag: _tag,
      );
    } else {
      AppLogger.warning(
        'Failed to load $label phone requests: ${response.message}',
        tag: _tag,
      );
    }

    return response;
  }

  /// Step 3 — PATCH `/{tier}-users/phone-requests/{id}/respond`
  /// with `{ "action": "approve" | "reject" }`.
  Future<ApiResponse<bool>> respond({
    required bool isVip,
    required String requestId,
    required bool approve,
  }) async {
    final action = approve ? 'approve' : 'reject';
    AppLogger.info(
      'Responding to phone request $requestId (vip=$isVip) action=$action',
      tag: _tag,
    );

    final response = await ApiClient.instance.patch<bool>(
      AppConstants.urls.phoneRequestRespond(isVip, requestId),
      data: {'action': action},
      parser: (_) => true,
    );

    if (response.success) {
      AppLogger.success(
        'Phone request $requestId $action succeeded',
        tag: _tag,
      );
    } else {
      AppLogger.warning(
        'Phone request $requestId $action failed: ${response.message}',
        tag: _tag,
      );
    }

    return response;
  }

  static String? _parsePhone(dynamic json) {
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
