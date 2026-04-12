import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

enum SnackBarType { success, error, warning, info }

class CommonSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _ModernSnackBar(
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
      ),
    );
    
    overlay.insert(overlayEntry);
  }

  // Convenience methods
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
}

class _ModernSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const _ModernSnackBar({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  State<_ModernSnackBar> createState() => _ModernSnackBarState();
}

class _ModernSnackBarState extends State<_ModernSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _progressController.forward();
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16.h,
      left: 16.w,
      right: 16.w,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _getGradient(widget.type),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getColor(widget.type).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Progress indicator
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: 1 - _progressController.value,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.8),
                                      ),
                                      minHeight: 3.h,
                                    );
                                  },
                                ),
                              ),
                              // Content
                              Padding(
                                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                                child: Row(
                                  children: [
                                    // Icon with pulse animation
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration: const Duration(milliseconds: 1000),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: EdgeInsets.all(10.w),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.25),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _getIcon(widget.type),
                                              color: Colors.white,
                                              size: 24.sp,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 16.w),
                                    // Message
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _getTitle(widget.type),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            widget.message,
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w400,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Close button
                                    GestureDetector(
                                      onTap: _dismiss,
                                      child: Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static LinearGradient _getGradient(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const LinearGradient(
          colors: [
            Color(0xFF00C851),
            Color(0xFF007E33),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SnackBarType.error:
        return const LinearGradient(
          colors: [
            Color(0xFFFF3547),
            Color(0xFFCC1B32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SnackBarType.warning:
        return const LinearGradient(
          colors: [
            Color(0xFFFFBB33),
            Color(0xFFFF8800),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SnackBarType.info:
        return const LinearGradient(
          colors: [
            Color(0xFF33B5E5),
            Color(0xFF0099CC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static Color _getColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF00C851);
      case SnackBarType.error:
        return const Color(0xFFFF3547);
      case SnackBarType.warning:
        return const Color(0xFFFFBB33);
      case SnackBarType.info:
        return const Color(0xFF33B5E5);
    }
  }

  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  static String _getTitle(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return 'Success';
      case SnackBarType.error:
        return 'Error';
      case SnackBarType.warning:
        return 'Warning';
      case SnackBarType.info:
        return 'Info';
    }
  }
}