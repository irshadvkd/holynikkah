// 🔥 HOME SCREEN (THEMED)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/category/screens/normal_category_screen.dart';
import 'package:holynikkah/modules/myprofile/screens/my_profile_screen.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:holynikkah/modules/template/screens/my_template_screen.dart';
import 'package:provider/provider.dart';

import 'package:holynikkah/core/services/home_session_storage.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';

import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/category/screens/vip_category_screen.dart';
import 'package:holynikkah/modules/partner/widgets/partner_full_screen_view.dart';
import 'package:holynikkah/modules/reels/screens/reels_screen.dart';
import 'package:holynikkah/modules/ads/screens/ads_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? initialIndex;

  const HomeScreen({super.key, this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _initSelectedIndex();
  }

  Future<void> _initSelectedIndex() async {
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
      await HomeSessionStorage().writeSelectedIndex(_selectedIndex);
      return;
    }

    final storedIndex = await HomeSessionStorage().readSelectedIndex();

    if (!mounted) return;

    if (storedIndex != null && storedIndex >= 0 && storedIndex <= 4) {
      setState(() => _selectedIndex = storedIndex);
    }
  }

  /// 🔥 VIP LOGIC
  Widget _buildVipScreen({
    required bool isLoggedIn,
    required bool isCategorySelected,
    required bool isTemplateSelected,
  }) {
    if (!isLoggedIn) {
      return const VipCategoryScreen(isSelectionRequired: false);
    }

    if (!isCategorySelected) {
      return VipCategoryScreen(
        isSelectionRequired: true,
        onNavigate: (index) {
          setState(() => _selectedIndex = index);
        },
      );
    }

    if (!isTemplateSelected) {
      return const MyTemplateScreen(isGate: true, gateIsVip: true);
    }

    return const PartnerFullScreenView(isVip: true);
  }

  /// 🔥 NORMAL LOGIC
  Widget _buildNormalScreen({
    required bool isLoggedIn,
    required bool isCategorySelected,
    required bool isTemplateSelected,
  }) {
    if (!isLoggedIn) {
      return const NormalCategoryScreen(isSelectionRequired: false);
    }

    if (!isCategorySelected) {
      return NormalCategoryScreen(
        isSelectionRequired: true,
        onNavigate: (index) {
          setState(() => _selectedIndex = index);
        },
      );
    }

    if (!isTemplateSelected) {
      return const MyTemplateScreen(isGate: true, gateIsVip: false);
    }

    return const PartnerFullScreenView(isVip: false);
  }

  @override
  Widget build(BuildContext context) {
    final isVipLoggedIn = context.watch<AuthProvider>().isVipLoggedIn;
    final isNormalLoggedIn = context.watch<AuthProvider>().isNormalLoggedIn;
    final categoryProvider = context.watch<CategoryProvider>();
    final templateProvider = context.watch<TemplateProvider>();

    /// 🔥 Loading state
    if (!categoryProvider.isLoaded || !templateProvider.selectionLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }



    final screens = <Widget>[
      _buildVipScreen(
        isLoggedIn: isVipLoggedIn,
        isCategorySelected: categoryProvider.isVipSelected,
        isTemplateSelected: templateProvider.isVipTemplateSelected,
      ),
      _buildNormalScreen(
        isLoggedIn: isNormalLoggedIn,
        isCategorySelected: categoryProvider.isNormalSelected,
        isTemplateSelected: templateProvider.isNormalTemplateSelected,
      ),
      const ReelsScreen(),
      const AdsScreen(),
      const MyProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// 🔥 BOTTOM NAVIGATION BAR (THEMED)
  Widget _buildBottomNavigation() {
    final isVipLoggedIn = context.watch<AuthProvider>().isVipLoggedIn;
    final isNormalLoggedIn = context.watch<AuthProvider>().isNormalLoggedIn;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconDefault,
        selectedFontSize: 11.sp,
        unselectedFontSize: 11.sp,
        currentIndex: _selectedIndex,
        selectedLabelStyle: AppTypography.marcellus(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        unselectedLabelStyle: AppTypography.marcellus(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        onTap: (index) async {
          setState(() => _selectedIndex = index);
          await HomeSessionStorage().writeSelectedIndex(index);
        },
        items: [
          /// 🔥 VIP / PROFILE
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 8),
              child: SvgPicture.asset(
                AppConstants.icons.vipRegister,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 0
                      ? AppColors.primary
                      : AppColors.iconDefault,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: isVipLoggedIn ? 'Vip Profile' : 'Vip Register',
          ),

          /// 🔥 REGISTER
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 8),
              child: SvgPicture.asset(
                AppConstants.icons.user,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 1
                      ? AppColors.primary
                      : AppColors.iconDefault,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: isNormalLoggedIn ? 'Profile' : 'Register',
          ),

          /// 🔥 REELS
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 8),
              child: SvgPicture.asset(
                AppConstants.icons.reels,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 2
                      ? AppColors.primary
                      : AppColors.iconDefault,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Reels',
          ),

          /// 🔥 ADS
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 8),
              child: SvgPicture.asset(
                AppConstants.icons.ads,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 3
                      ? AppColors.primary
                      : AppColors.iconDefault,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'Ads',
          ),

          /// 🔥 DONATERS
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 8),
              child: SvgPicture.asset(
                AppConstants.icons.menu,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 4
                      ? AppColors.primary
                      : AppColors.iconDefault,
                  BlendMode.srcIn,
                ),
              ),
            ),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }
}
