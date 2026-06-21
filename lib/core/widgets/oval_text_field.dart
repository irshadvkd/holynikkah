import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';

class OvalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final TextCapitalization? textCapitalization;

  const OvalTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.inputFormatters,
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
    this.textCapitalization,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          color: Colors.black87,
        ),
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide(
              color: const Color(0xFFFFD700),
              width: 2.w,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2.w,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2.w,
            ),
          ),
          counterText: '', // Hide character counter
        ),
      ),
    );
  }
}