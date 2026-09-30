import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/myprofile/screens/profile_update_screen.dart';
import 'package:provider/provider.dart';

class MyProfileDetailScreen extends StatefulWidget {
  const MyProfileDetailScreen({super.key});

  @override
  State<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends State<MyProfileDetailScreen> {
  bool isVipSelected = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    if (auth.isNormalLoggedIn && !auth.isVipLoggedIn) {
      isVipSelected = false;
    } else if (auth.isVipLoggedIn && !auth.isNormalLoggedIn) {
      isVipSelected = true;
    } else {
      isVipSelected = profile.isVipProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    // Tab visibility logic:
    // Only show VIP/Normal toggle tabs if BOTH normal and VIP users are logged in.
    final bool showTabs = auth.isVipLoggedIn && auth.isNormalLoggedIn;
    if (!showTabs) {
      if (auth.isNormalLoggedIn && !auth.isVipLoggedIn) {
        isVipSelected = false;
      } else if (auth.isVipLoggedIn && !auth.isNormalLoggedIn) {
        isVipSelected = true;
      }
    }

    final name = profileProvider.getName(isVipSelected);
    final phone = profileProvider.getPhone(isVipSelected);
    final gender = profileProvider.getGender(isVipSelected);
    final state = profileProvider.getState(isVipSelected);
    final district = profileProvider.getDistrict(isVipSelected);
    final city = profileProvider.getCity(isVipSelected);
    final categoryName = profileProvider.getCategoryName(isVipSelected);
    final info = profileProvider.getInfo(isVipSelected);
    final imagePath = profileProvider.getProfileImagePath(isVipSelected);
    final isNetwork = profileProvider.isProfileImageNetworkTier(isVipSelected);
    final networkUrl = profileProvider.getProfileImageNetworkUrlTier(isVipSelected);

    return CommonAppBar(
      title: isVipSelected ? 'VIP PROFILE' : 'MY PROFILE',
      gradient: AppColors.darkGreenGradient,
      backgroundColor: AppColors.secondary,
      titleColor: Colors.white,
      leadingIconColor: AppColors.goldLight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Selector Tab (ONLY displayed when BOTH normal and VIP are logged in)
              if (showTabs) ...[
                _buildProfileSelector(),
                SizedBox(height: 24.h),
              ] else
                SizedBox(height: 8.h),

              // 2. Avatar Header
              _buildAvatarHeader(
                imagePath: imagePath,
                isNetwork: isNetwork,
                networkUrl: networkUrl,
                name: name,
                isVip: isVipSelected,
              ),

              SizedBox(height: 24.h),

              // 3. Information Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E182A).withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFE3C78F).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24.r,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: AppColors.goldLight,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isVipSelected
                              ? 'VIP Profile Information'
                              : 'Profile Information',
                          style: AppTypography.marcellus(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Divider(
                      color: const Color(0xFFE3C78F).withValues(alpha: 0.16),
                      thickness: 1,
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoRow('Name', name.isEmpty ? 'Not set' : name),
                    _buildInfoRow('Phone', phone.isEmpty ? 'Not set' : phone),
                    _buildInfoRow('Gender', gender.isEmpty ? 'Not set' : gender),
                    _buildInfoRow('State', state ?? 'Not set'),
                    _buildInfoRow('District', district ?? 'Not set'),
                    _buildInfoRow('City', city ?? 'Not set'),
                    if (categoryName != null && categoryName.isNotEmpty)
                      _buildInfoRow('Category', categoryName),
                    _buildInfoRow(
                      'Information',
                      info.isEmpty ? 'Not set' : info,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // 4. Update Profile Button
              CommonButton(
                title: isVipSelected ? 'Edit VIP Profile' : 'Edit Profile',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileUpdateScreen(isVip: isVipSelected),
                    ),
                  );
                  if (context.mounted) {
                    final authProvider = context.read<AuthProvider>();
                    context.read<ProfileProvider>().fetchProfiles(authProvider: authProvider);
                  }
                },
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0E182A).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3C78F).withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isVipSelected) {
                  setState(() => isVipSelected = true);
                }
              },
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: isVipSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFC9A15F),
                            Color(0xFFE3C78F),
                          ],
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    'VIP Profile',
                    style: AppTypography.marcellus(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isVipSelected
                          ? const Color(0xFF0A1220)
                          : const Color(0xFFCBB388).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isVipSelected) {
                  setState(() => isVipSelected = false);
                }
              },
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: !isVipSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFC9A15F),
                            Color(0xFFE3C78F),
                          ],
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Normal Profile',
                    style: AppTypography.marcellus(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: !isVipSelected
                          ? const Color(0xFF0A1220)
                          : const Color(0xFFCBB388).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader({
    required String? imagePath,
    required bool isNetwork,
    required String networkUrl,
    required String name,
    required bool isVip,
  }) {
    final bool hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        imagePath != '0' &&
        imagePath != 'null';

    return Column(
      children: [
        Container(
          width: 104.sp,
          height: 104.sp,
          padding: EdgeInsets.all(3.sp),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE3C78F),
                Color(0xFFC9A15F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 6),
                blurRadius: 18.r,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF0E1F16),
              child: hasImage
                  ? (isNetwork
                      ? CustomNetworkImage(
                          url: networkUrl,
                          width: 100.sp,
                          height: 100.sp,
                          fit: BoxFit.cover,
                          errorWidget: Center(
                            child: SvgPicture.string(
                              '''<svg viewBox="0 0 24 24" fill="none">
                                <circle cx="12" cy="8" r="4" fill="#C9A15F"/>
                                <path d="M4 20c0-4 4-6 8-6s8 2 8 6" fill="#C9A15F"/>
                              </svg>''',
                              width: 48.sp,
                              height: 48.sp,
                            ),
                          ),
                        )
                      : Image.file(
                          File(imagePath),
                          width: 100.sp,
                          height: 100.sp,
                          fit: BoxFit.cover,
                        ))
                  : Center(
                      child: SvgPicture.string(
                        '''<svg viewBox="0 0 24 24" fill="none">
                          <circle cx="12" cy="8" r="4" fill="#C9A15F"/>
                          <path d="M4 20c0-4 4-6 8-6s8 2 8 6" fill="#C9A15F"/>
                        </svg>''',
                        width: 48.sp,
                        height: 48.sp,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          name.isNotEmpty ? name : 'My Profile',
          textAlign: TextAlign.center,
          style: AppTypography.marcellus(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF4ECDD),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isVip
                ? const Color(0xFFC9A15F).withValues(alpha: 0.2)
                : const Color(0xFF10241A),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isVip
                  ? const Color(0xFFE3C78F)
                  : const Color(0xFFE3C78F).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            isVip ? 'VIP ACCOUNT' : 'NORMAL ACCOUNT',
            style: AppTypography.marcellus(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isVip ? AppColors.goldLight : const Color(0xFFCBB388),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: AppTypography.marcellus(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCBB388).withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: AppTypography.marcellus(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF4ECDD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
