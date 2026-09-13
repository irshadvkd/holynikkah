import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/utils.dart';
import 'package:holynikkah/modules/category/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final bool isVip;
  final Categories category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool withCategories;
  final bool isSelectionRequired;
  final TextStyle? textStyle;

  const CategoryCard({
    super.key,
    required this.isVip,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.withCategories = true,
    required this.isSelectionRequired,
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
        padding: isVip ? EdgeInsets.all(16.w) : EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          //   colors: [
          //     Color(0xF01F2421), // Dark greenish-gray
          //     Color(0xFF938F8F), // Medium gray
          //   ],
          // ),
          color: hexToColor(category.bgColor),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF303036).withOpacity(.7),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            if (isSelectionRequired == true)
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green : Colors.grey,
                size: 16,
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: isVip
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVip == true)
                    Text(
                      "Class",
                      style: AppTypography.marcellus(
                        color: hexToColor(category.textColor),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    category.name?.toUpperCase() ?? "",
                    style:
                        textStyle ??
                        AppTypography.marcellus(
                          color: hexToColor(category.textColor),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: isVip ? TextAlign.start : TextAlign.center,
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
                  decoration: BoxDecoration(
                    color: hexToColor(category.textColor),
                  ),
                ),
              ),
            if (isVip == true)
              SizedBox(
                width: 125.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Networth',
                      style: AppTypography.marcellus(
                        color: hexToColor(category.textColor),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      width: 125.w,
                      child: Text(
                        '${category.networth}',
                        style: AppTypography.marcellus(
                          color: hexToColor(category.textColor),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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
