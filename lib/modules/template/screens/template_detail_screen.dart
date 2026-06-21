import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';

class TemplateDetailScreen extends StatelessWidget {
  final String templateId;
  final String templateName;
  final String templateDescription;
  final String templateCategory;
  final bool isVip;

  const TemplateDetailScreen({
    super.key,
    required this.templateId,
    required this.templateName,
    required this.templateDescription,
    required this.templateCategory,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.inputText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isVip ? 'VIP Template Details' : 'Template Details',
          style: GoogleFonts.inter(
            color: AppColors.inputText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.inputBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isVip ? Color(0xFF032544) : AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          isVip ? 'VIP' : 'STANDARD',
                          style: GoogleFonts.inter(
                            color: isVip ? AppColors.pureWhite : AppColors.inputText,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        templateId,
                        style: GoogleFonts.inter(
                          color: AppColors.inputHint,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    templateName,
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF032544),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Category: $templateCategory',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inputText,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inputText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    templateDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.inputHint,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      CommonSnackBar.showInfo(
                        context,
                        'Template preview feature coming soon',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF032544),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Preview Template',
                      style: GoogleFonts.inter(
                        color: AppColors.pureWhite,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      CommonSnackBar.showInfo(
                        context,
                        'Template sharing feature coming soon',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inputBorder,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Share Template',
                      style: GoogleFonts.inter(
                        color: AppColors.inputText,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}