import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? loaderColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final bool hasShadow;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? prefixIcon;
  final TextStyle? textStyle;

  const CommonButton({
    super.key,
    required this.title,
    this.isLoading = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.loaderColor,
    this.gradient,
    this.width,
    this.height,
    this.boxShadow,
    this.hasShadow = true,
    this.borderRadius,
    this.padding,
    this.margin,
    this.prefixIcon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final effectiveText = textColor ?? AppColors.onPrimary;
    final effectiveLoader = loaderColor ?? effectiveText;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 52.h,
        padding: padding,
        margin: margin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(50.r),
          color: gradient != null ? null : effectiveBg,
          gradient: gradient,
          boxShadow: hasShadow
              ? (boxShadow ??
                  [
                    BoxShadow(
                      color: effectiveBg.withValues(alpha: 0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ])
              : null,
        ),
        child: isLoading
            ? SizedBox(
                height: 22.h,
                width: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveLoader),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    SizedBox(width: 10.w),
                  ],
                  Text(
                    title,
                    style: textStyle ??
                        AppTypography.marcellus(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: effectiveText,
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
