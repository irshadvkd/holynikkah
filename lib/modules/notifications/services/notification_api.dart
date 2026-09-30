import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/notifications/models/in_app_notification_model.dart';

class NotificationsFetchResult {
  final int unreadCount;
  final List<InAppNotificationItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const NotificationsFetchResult({
    required this.unreadCount,
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Central API Service for In-App and Push Notifications
class NotificationApi {
  NotificationApi._();

  static final NotificationApi instance = NotificationApi._();
  static const String _tag = 'NotificationApi';

  /// Register or update FCM device token on backend
  Future<bool> registerDeviceToken({
    required bool isVip,
    required String fcmToken,
  }) async {
    try {
      AppLogger.info('Registering device token (isVip: $isVip)', tag: _tag);
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        AppConstants.urls.deviceToken(isVip),
        data: {'fcm_token': fcmToken},
      );
      return response.success;
    } catch (e) {
      AppLogger.error('Error registering device token: $e', tag: _tag);
      return false;
    }
  }

  /// Remove FCM device token on logout
  Future<bool> removeDeviceToken({required bool isVip}) async {
    try {
      AppLogger.info('Removing device token (isVip: $isVip)', tag: _tag);
      final response = await ApiClient.instance.delete<Map<String, dynamic>>(
        AppConstants.urls.deviceToken(isVip),
      );
      return response.success;
    } catch (e) {
      AppLogger.error('Error removing device token: $e', tag: _tag);
      return false;
    }
  }

  /// Fetch paginated notifications & unread count
  Future<ApiResponse<NotificationsFetchResult>> fetchNotifications({
    required bool isVip,
    int page = 1,
    int pageSize = 20,
  }) async {
    AppLogger.info('Fetching notifications (isVip: $isVip, page: $page)', tag: _tag);

    return await ApiClient.instance.get<NotificationsFetchResult>(
      AppConstants.urls.notifications(isVip),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      parser: (json) {
        if (json is! Map) {
          return const NotificationsFetchResult(unreadCount: 0, items: []);
        }

        final data = json['data'] as Map<String, dynamic>? ?? {};
        final unreadCount = data['unread_count'] as int? ??
            json['unread_count'] as int? ??
            0;

        List rawItems = [];
        if (data['items'] is List) {
          rawItems = data['items'] as List;
        } else if (data['data'] is List) {
          rawItems = data['data'] as List;
        } else if (json['items'] is List) {
          rawItems = json['items'] as List;
        }

        final items = rawItems
            .whereType<Map<String, dynamic>>()
            .map((e) => InAppNotificationItem.fromJson(e))
            .toList();

        final currentPage = data['current_page'] as int? ?? page;
        final lastPage = data['last_page'] as int? ?? 1;
        final total = data['total'] as int? ?? items.length;

        return NotificationsFetchResult(
          unreadCount: unreadCount,
          items: items,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
        );
      },
    );
  }

  /// Mark single notification as read
  Future<bool> markAsRead({
    required bool isVip,
    required int notificationId,
  }) async {
    try {
      AppLogger.info('Marking notification #$notificationId as read', tag: _tag);
      final response = await ApiClient.instance.patch<Map<String, dynamic>>(
        AppConstants.urls.notificationRead(isVip, notificationId),
      );
      return response.success;
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e', tag: _tag);
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead({required bool isVip}) async {
    try {
      AppLogger.info('Marking all notifications as read', tag: _tag);
      final response = await ApiClient.instance.patch<Map<String, dynamic>>(
        AppConstants.urls.notificationsMarkAllRead(isVip),
      );
      return response.success;
    } catch (e) {
      AppLogger.error('Error marking all notifications as read: $e', tag: _tag);
      return false;
    }
  }

  /// Record profile view & trigger visitor notification on backend
  Future<bool> recordProfileView({
    required bool isVip,
    required int targetId,
  }) async {
    try {
      AppLogger.info('Recording profile view for targetId=$targetId', tag: _tag);
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        AppConstants.urls.profileView(isVip, targetId),
      );
      return response.success;
    } catch (e) {
      AppLogger.error('Error recording profile view: $e', tag: _tag);
      return false;
    }
  }
}
