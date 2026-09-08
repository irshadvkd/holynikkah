import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

class CommonBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const CommonBadge({
    super.key,
    required this.text,
    this.backgroundColor = Colors.amber,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: AppTypography.marcellus(
          fontSize: 10.sp,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}