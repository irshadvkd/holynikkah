import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/services/notification_service.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/notifications/models/in_app_notification_model.dart';
import 'package:holynikkah/modules/notifications/services/notification_api.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<InAppNotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications(refresh: true);
  }

  bool _getIsVip() {
    final auth = context.read<AuthProvider>();
    if (auth.isVipLoggedIn) return true;
    return false;
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    final isVip = _getIsVip();
    final response = await NotificationApi.instance.fetchNotifications(
      isVip: isVip,
      page: _currentPage,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      setState(() {
        if (refresh) {
          _notifications.clear();
          _notifications.addAll(data.items);
        } else {
          _notifications.addAll(data.items);
        }
        _hasMore = data.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        NotificationService.instance.unreadCountNotifier.value = data.unreadCount;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = response.message ?? 'Failed to load notifications';
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage += 1;
    });

    await _loadNotifications(refresh: false);
  }

  Future<void> _markAllAsRead() async {
    final isVip = _getIsVip();
    final success = await NotificationApi.instance.markAllAsRead(isVip: isVip);
    if (!mounted) return;

    if (success) {
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        NotificationService.instance.unreadCountNotifier.value = 0;
      });
    }
  }

  Future<void> _onItemTapped(InAppNotificationItem item, int index) async {
    final isVip = _getIsVip();
    if (!item.isRead) {
      // Optimistic update
      setState(() {
        _notifications[index] = item.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        final current = NotificationService.instance.unreadCountNotifier.value;
        if (current > 0) {
          NotificationService.instance.unreadCountNotifier.value = current - 1;
        }
      });
      await NotificationApi.instance.markAsRead(
        isVip: isVip,
        notificationId: item.id,
      );
    }

    if (!mounted) return;
    NotificationService.instance.handleNotificationRouting(
      item.data.isNotEmpty ? item.data : {'type': item.type},
      context: context,
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'phone_request_incoming':
        return Icons.phone_callback_rounded;
      case 'phone_request_approved':
        return Icons.check_circle_outline_rounded;
      case 'phone_request_rejected':
        return Icons.cancel_outlined;
      case 'profile_view':
        return Icons.visibility_outlined;
      case 'profile_verified':
        return Icons.verified_user_rounded;
      case 'welcome':
        return Icons.celebration_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'phone_request_incoming':
        return const Color(0xFF4A90E2);
      case 'phone_request_approved':
        return AppColors.success;
      case 'phone_request_rejected':
        return AppColors.error;
      case 'profile_view':
        return const Color(0xFFBA68C8);
      case 'profile_verified':
        return const Color(0xFF26A69A);
      case 'welcome':
        return AppColors.goldLight;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.darkGreenGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.goldLight,
              size: 20.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: AppTypography.cormorantGaramond(
              color: AppColors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            if (hasUnread)
              TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: AppTypography.marcellus(
                    color: AppColors.goldLight,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldLight),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: AppColors.white, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _loadNotifications(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        color: AppColors.goldLight,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 160.h),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.goldLight.withOpacity(0.6),
                      size: 36.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Notifications Yet',
                    style: AppTypography.cormorantGaramond(
                      color: AppColors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'We will notify you when something important happens.',
                    style: GoogleFonts.inter(
                      color: AppColors.goldLight.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      color: AppColors.goldLight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              _hasMore &&
              !_isLoadingMore) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            if (index == _notifications.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.goldLight),
                ),
              );
            }

            final item = _notifications[index];
            final typeColor = _getColorForType(item.type);

            return InkWell(
              onTap: () => _onItemTapped(item, index),
              borderRadius: BorderRadius.circular(16.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: item.isRead
                      ? const Color(0xFF0E182A).withOpacity(0.45)
                      : const Color(0xFF16264C).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: item.isRead
                        ? const Color(0xFFE3C78F).withOpacity(0.12)
                        : AppColors.goldLight.withOpacity(0.45),
                    width: item.isRead ? 1.0 : 1.5,
                  ),
                  boxShadow: item.isRead
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.goldLight.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Icon
                    Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: typeColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getIconForType(item.type),
                        color: typeColor,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTypography.marcellus(
                                    color: AppColors.white,
                                    fontSize: 14.sp,
                                    fontWeight: item.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (item.createdAt != null) ...[
                                SizedBox(width: 8.w),
                                Text(
                                  _formatTimeAgo(item.createdAt),
                                  style: GoogleFonts.inter(
                                    color: AppColors.goldLight.withOpacity(0.6),
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.message,
                            style: GoogleFonts.inter(
                              color: item.isRead
                                  ? AppColors.white.withOpacity(0.7)
                                  : AppColors.white.withOpacity(0.95),
                              fontSize: 12.sp,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unread indicator dot
                    if (!item.isRead) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 8.w,
                        height: 8.h,
                        margin: EdgeInsets.only(top: 4.h),
                        decoration: const BoxDecoration(
                          color: AppColors.goldLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
