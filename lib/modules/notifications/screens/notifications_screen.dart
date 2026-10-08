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
import 'package:holynikkah/modules/notifications/widgets/notification_detail_dialog.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  final bool? initialIsVip;

  const NotificationsScreen({
    super.key,
    this.initialIsVip,
  });

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
  late bool _isVip;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _isVip = widget.initialIsVip ?? (auth.isVipLoggedIn || !auth.isNormalLoggedIn);
    _loadNotifications(refresh: true);
  }

  bool _getIsVip() => _isVip;

  void _onTierChanged(bool isVip) {
    if (_isVip == isVip) return;
    setState(() {
      _isVip = isVip;
      _notifications.clear();
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });
    _loadNotifications(refresh: true);
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isVipLoggedIn && !auth.isNormalLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
          _errorMessage = null;
          _notifications.clear();
        });
        NotificationService.instance.unreadCountNotifier.value = 0;
      }
      return;
    }

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
      NotificationApi.instance.markAsRead(
        isVip: isVip,
        notificationId: item.id,
      );
    }

    if (!mounted) return;
    await NotificationDetailDialog.show(context, _notifications[index]);
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
    final auth = context.watch<AuthProvider>();
    final hasVip = auth.isVipLoggedIn;
    final hasNormal = auth.isNormalLoggedIn;

    if (_isVip && !hasVip && hasNormal) _isVip = false;
    if (!_isVip && !hasNormal && hasVip) _isVip = true;

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
        body: Column(
          children: [
            if (hasVip && hasNormal) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: _buildTierSelector(),
              ),
            ],
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tierSegment('VIP', _isVip, () => _onTierChanged(true)),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _tierSegment('Normal', !_isVip, () => _onTierChanged(false)),
          ),
        ],
      ),
    );
  }

  Widget _tierSegment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.cormorantGaramond(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                      color: AppColors.goldLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.goldLight.withValues(alpha: 0.6),
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
                      color: AppColors.goldLight.withValues(alpha: 0.7),
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
                      ? const Color(0xFF0E182A).withValues(alpha: 0.45)
                      : const Color(0xFF16264C).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: item.isRead
                        ? const Color(0xFFE3C78F).withValues(alpha: 0.12)
                        : AppColors.goldLight.withValues(alpha: 0.45),
                    width: item.isRead ? 1.0 : 1.5,
                  ),
                  boxShadow: item.isRead
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.goldLight.withValues(alpha: 0.08),
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
                        color: typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.35),
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
                                    color: AppColors.goldLight.withValues(alpha: 0.6),
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
                                  ? AppColors.white.withValues(alpha: 0.7)
                                  : AppColors.white.withValues(alpha: 0.95),
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
