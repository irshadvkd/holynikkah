import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/myprofile/screens/vip_profile_update_screen.dart';
import 'package:holynikkah/modules/myprofile/screens/profile_update_screen.dart';
import 'package:provider/provider.dart';

class MyProfileDetailScreen extends StatefulWidget {
  const MyProfileDetailScreen({super.key});

  @override
  State<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends State<MyProfileDetailScreen> {
  bool isVipSelected = true;

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
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isVipSelected = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isVipSelected ? Color(0xFF032544) : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isVipSelected ? Color(0xFF032544) : AppColors.inputBorder,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        "VIP Profile",
                        style: AppTypography.marcellus(
                          color: isVipSelected ? AppColors.pureWhite : AppColors.inputText,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isVipSelected = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isVipSelected ? Color(0xFF032544) : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: !isVipSelected ? Color(0xFF032544) : AppColors.inputBorder,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        "Profile",
                        style: AppTypography.marcellus(
                          color: !isVipSelected ? AppColors.pureWhite : AppColors.inputText,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Expanded(
              child: Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  return Column(
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
                            Text(
                              isVipSelected ? 'VIP Profile Information' : 'Profile Information',
                              style: AppTypography.marcellus(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF032544),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildInfoRow('Name:', profileProvider.getName(isVipSelected).isEmpty ? 'Not set' : profileProvider.getName(isVipSelected)),
                            _buildInfoRow('Phone:', profileProvider.getPhone(isVipSelected).isEmpty ? 'Not set' : profileProvider.getPhone(isVipSelected)),
                            _buildInfoRow('Gender:', profileProvider.getGender(isVipSelected).isEmpty ? 'Not set' : profileProvider.getGender(isVipSelected)),
                            _buildInfoRow('State:', profileProvider.getState(isVipSelected) ?? 'Not set'),
                            _buildInfoRow('District:', profileProvider.getDistrict(isVipSelected) ?? 'Not set'),
                            _buildInfoRow('City:', profileProvider.getCity(isVipSelected) ?? 'Not set'),
                            _buildInfoRow('Information:', profileProvider.getInfo(isVipSelected).isEmpty ? 'Not set' : profileProvider.getInfo(isVipSelected)),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isVipSelected) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VipProfileUpdateScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileUpdateScreen(),
                                ),
                              );
                            }
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
                            isVipSelected ? 'Update VIP Profile' : 'Update Profile',
                            style: AppTypography.marcellus(
                              color: AppColors.pureWhite,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: AppTypography.marcellus(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.inputText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.marcellus(
                fontSize: 14.sp,
                color: AppColors.inputHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
