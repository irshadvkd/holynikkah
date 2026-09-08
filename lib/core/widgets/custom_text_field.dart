import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

/// 🔹 Reusable text field with optional validation, prefix/suffix icons, and theming
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final bool readOnly;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Color? cursorColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines,
    this.maxLength,
    this.inputFormatters,
    this.enabled,
    this.readOnly = false,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.borderColor,
    this.boxShadow,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: borderColor ?? Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: const Color(0xFF303036).withValues(alpha: 0.7),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        enabled: enabled,
        readOnly: readOnly,
        cursorColor: cursorColor,
        style: AppTypography.marcellus(
          color: textColor ?? AppColors.textPrimary,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.marcellus(
            color: hintColor ?? AppColors.textSecondary,
            fontSize: 16.sp,
          ),
          filled: false,
          counterText: "",
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
        ),
      ),
    );
  }
}
