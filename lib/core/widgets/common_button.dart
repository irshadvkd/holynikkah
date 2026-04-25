import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback? onTap;
  const CommonButton({
    super.key,
    required this.title,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300.w,
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF303036).withOpacity(.7),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}
