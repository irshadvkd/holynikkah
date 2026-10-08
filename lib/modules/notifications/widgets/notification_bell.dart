import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/services/notification_service.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/modules/notifications/screens/notifications_screen.dart';

class NotificationBellButton extends StatelessWidget {
  final Color? iconColor;
  final double? size;

  const NotificationBellButton({
    super.key,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.goldLight;
    final effectiveSize = size ?? 24.sp;

    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCountNotifier,
      builder: (context, unreadCount, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: effectiveSize,
                color: effectiveColor,
              ),
              splashRadius: 22.r,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2.h,
                right: -4.w,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: unreadCount > 9 ? 4.w : 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.surface,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
