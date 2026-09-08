import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

enum SnackBarType { success, error, warning, info }

class CommonSnackBar {
  CommonSnackBar._();

  static OverlayEntry? _currentEntry;

  static const Color _backgroundColor = Color(0xFF323232);

  static const Map<SnackBarType, Color> _accentColors = {
    SnackBarType.success: Color(0xFF81C784),
    SnackBarType.error: Color(0xFFEF5350),
    SnackBarType.warning: Color(0xFFFFD740),
    SnackBarType.info: Color(0xFF29B6F6),
  };

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final hasAction = actionLabel != null && onActionPressed != null;
    final resolvedDuration = duration ??
        Duration(
          seconds: hasAction
              ? 5
              : type == SnackBarType.error || type == SnackBarType.warning
                  ? 4
                  : 3,
        );

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (overlayContext) => _SnackBarOverlay(
        message: message,
        type: type,
        duration: resolvedDuration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        bottomInset: _bottomInset(overlayContext),
        onDismiss: () {
          overlayEntry.remove();
          if (_currentEntry == overlayEntry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }

  static double _bottomInset(BuildContext context) {
    final padding = MediaQuery.of(context).padding.bottom;
    var inset = padding + 16.h;

    if (context.findAncestorWidgetOfExactType<BottomNavigationBar>() != null) {
      inset += kBottomNavigationBarHeight;
    }

    return inset;
  }

  static Color _accentColor(SnackBarType type) => _accentColors[type]!;

  static IconData _icon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }
}

class _SnackBarOverlay extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final double bottomInset;
  final VoidCallback onDismiss;

  const _SnackBarOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.actionLabel,
    required this.onActionPressed,
    required this.bottomInset,
    required this.onDismiss,
  });

  @override
  State<_SnackBarOverlay> createState() => _SnackBarOverlayState();
}

class _SnackBarOverlayState extends State<_SnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = CommonSnackBar._accentColor(widget.type);
    final hasAction =
        widget.actionLabel != null && widget.onActionPressed != null;

    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: widget.bottomInset,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('common_snackbar'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: CommonSnackBar._backgroundColor,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      CommonSnackBar._icon(widget.type),
                      color: accentColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.marcellus(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (hasAction) ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {
                          widget.onActionPressed!();
                          _dismiss();
                        },
                        child: Text(
                          widget.actionLabel!,
                          style: AppTypography.marcellus(
                            color: accentColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
