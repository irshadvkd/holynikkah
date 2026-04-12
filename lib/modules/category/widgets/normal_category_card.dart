import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';

class SearchCategoryCard extends StatelessWidget {
  final Categories category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool withCategories;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const SearchCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.withCategories = true,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(0),
        padding: padding ?? EdgeInsets.all(8.w),
        alignment: Alignment.center,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.grey,
              size: 16,
            ),
            SizedBox(width: 8.w),
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
          ],
        ),
      ),
    );
  }
}
