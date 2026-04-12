import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final bool isVip;
  final Categories category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool withCategories;
  final TextStyle? textStyle;

  const CategoryCard({
    super.key,
    required this.isVip,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.withCategories = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isVip
            ? EdgeInsets.symmetric(vertical: 8.h, horizontal: 19.w)
            : EdgeInsets.all(0),
        padding: isVip
            ?  EdgeInsets.all(16.w) :EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF01F2421), // Dark greenish-gray
              Color(0xFF938F8F), // Medium gray
            ],
          ),

          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF8F7F7),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.grey,
              size: 16,
            ),
            SizedBox(width: 8.w),
            if (isVip == true) ...[
              SvgPicture.asset(
                category.icon ?? "",
                width: 19.sp,
                height: 17.sp,
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVip == true)
                    Text(
                      "Class",
                      style: GoogleFonts.inter(
                        color: Color(0xFFFFFFFF),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    category.name?.toUpperCase() ?? "",
                    style:
                        textStyle ??
                        GoogleFonts.inter(
                          color: Color(0xFFFFFFFF),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (category.networth != "") ...[SizedBox(height: 4.h)],
                ],
              ),
            ),
            if (isVip == true)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Container(
                  width: 1,
                  height: 50.h,
                  decoration: BoxDecoration(color: Color(0xFF303036)),
                ),
              ),
            if (isVip == true)
              SizedBox(
                width: 80.w,
                child: Column(
                  children: [
                    Text(
                      'Networth',
                      style: GoogleFonts.inter(
                        color: Color(0xFFFFFFFF),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${category.networth}',
                      style: GoogleFonts.inter(
                        color: Color(0xFFFFFFFF),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
