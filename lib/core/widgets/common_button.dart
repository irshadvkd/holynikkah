import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/context_extension.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final LinearGradient? linearGradient;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.linearGradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.r),
            color: backgroundColor ?? AppColors.brandYellow,
            gradient: linearGradient,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? CircularProgressIndicator(
                  color: textColor ?? Colors.black,
                  strokeWidth: 2,
                )
              : Text(
                  text,
                  style: GoogleFonts.inter(
                    color: textColor ?? Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
