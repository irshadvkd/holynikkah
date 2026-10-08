import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/modules/notifications/models/in_app_notification_model.dart';

class NotificationDetailDialog extends StatelessWidget {
  const NotificationDetailDialog({
    super.key,
    required this.item,
  });

  final InAppNotificationItem item;

  static Future<void> show(BuildContext context, InAppNotificationItem item) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => NotificationDetailDialog(item: item),
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'phone_request_incoming':
        return 'Phone Request';
      case 'phone_request_approved':
        return 'Request Approved';
      case 'phone_request_rejected':
        return 'Request Declined';
      case 'profile_view':
        return 'Profile View';
      case 'profile_verified':
        return 'Verification';
      case 'welcome':
        return 'Welcome';
      default:
        return 'Notification';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dateTime.day}, ${dateTime.year} · $hour:$minute $period';
  }

  String? _getActionLabel(String type) {
    switch (type) {
      case 'phone_request_incoming':
        return 'View Phone Requests';
      case 'phone_request_approved':
      case 'phone_request_rejected':
        return 'View Outgoing Requests';
      case 'profile_verified':
      case 'welcome':
        return 'View Profile';
      default:
        return null;
    }
  }

  void _handleAction(BuildContext context) {
    Navigator.of(context).pop(); // Close dialog first

    final type = item.type;
    final route = item.data['route']?.toString();

    if (type == 'phone_request_incoming' || route == '/phone-requests/incoming') {
      Navigator.pushNamed(
        context,
        Routes.phoneRequests,
        arguments: {'initialIsIncoming': true},
      );
    } else if (type == 'phone_request_approved' ||
        type == 'phone_request_rejected' ||
        route == '/phone-requests/outgoing') {
      Navigator.pushNamed(
        context,
        Routes.phoneRequests,
        arguments: {'initialIsIncoming': false},
      );
    } else if (type == 'profile_verified' || type == 'welcome') {
      Navigator.pushNamed(context, Routes.home, arguments: {'initialIndex': 4});
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getColorForType(item.type);
    final actionLabel = _getActionLabel(item.type);
    final formattedTime = _formatDateTime(item.createdAt);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF16264C),
              Color(0xFF0E182A),
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.goldLight.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 14.w, 0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForType(item.type),
                          color: typeColor,
                          size: 13.sp,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _getTypeLabel(item.type),
                          style: GoogleFonts.inter(
                            color: typeColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 22.sp,
                    ),
                    splashRadius: 18.r,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Main Body Content
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: AppTypography.cormorantGaramond(
                      color: AppColors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (formattedTime.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        color: AppColors.goldLight.withValues(alpha: 0.7),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  Container(
                    height: 1,
                    color: AppColors.white.withValues(alpha: 0.08),
                  ),
                  SizedBox(height: 14.h),
                  // Message
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 13.5.sp,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // Actions Footer
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 18.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  if (actionLabel != null) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () => _handleAction(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldLight,
                          foregroundColor: const Color(0xFF0E182A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          actionLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E182A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
