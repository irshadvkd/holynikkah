/// 🔥 HOME SCREEN (FINAL + OLD BOTTOM BAR UI)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/category/screens/normal_category_screen.dart';
import 'package:holynikkah/modules/myprofile/screens/my_profile_screen.dart';
import 'package:provider/provider.dart';

import 'package:holynikkah/core/services/home_session_storage.dart';
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

    return PartnerFullScreenView(
      imageUrls: [
        'assets/sample/partner1.png',
        'assets/sample/partner2.png',
        'assets/sample/partner3.png',
        'assets/sample/partner4.png',
      ],
    );
  }

  /// 🔥 NORMAL LOGIC
  Widget _buildNormalScreen({
    required bool isLoggedIn,
    required bool isCategorySelected,
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

    return PartnerFullScreenView(
      imageUrls: [
        'assets/sample/partner1.png',
        'assets/sample/partner2.png',
        'assets/sample/partner3.png',
        'assets/sample/partner4.png',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVipLoggedIn = context.watch<AuthProvider>().isVipLoggedIn;
    final isNormalLoggedIn = context.watch<AuthProvider>().isNormalLoggedIn;
    final categoryProvider = context.watch<CategoryProvider>();

    /// 🔥 Loading state
    if (!categoryProvider.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = <Widget>[
      _buildVipScreen(
        isLoggedIn: isVipLoggedIn,
        isCategorySelected: categoryProvider.isVipSelected,
      ),
      _buildNormalScreen(
        isLoggedIn: isNormalLoggedIn,
        isCategorySelected: categoryProvider.isNormalSelected,
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

  /// 🔥 YOUR ORIGINAL BOTTOM NAV (RESTORED)
  Widget _buildBottomNavigation() {
    final isVipLoggedIn = context.watch<AuthProvider>().isVipLoggedIn;
    final isNormalLoggedIn = context.watch<AuthProvider>().isNormalLoggedIn;

    return BottomNavigationBar(
      backgroundColor: Color(0xFF032544),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFF616161).withAlpha(240),

      selectedFontSize: 10.sp,
      unselectedFontSize: 10.sp,
      currentIndex: _selectedIndex,


      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),

      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),


      onTap: (index) async {
        setState(() => _selectedIndex = index);
        await HomeSessionStorage().writeSelectedIndex(index);
      },

      items: [
        /// 🔥 VIP / PROFILE
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12),
            child: SvgPicture.asset(
              AppConstants.icons.vipRegister,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0
                    ? Colors.white
                    : const Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: isVipLoggedIn ? 'Vip Profile' : 'Vip Register',
        ),

        /// 🔥 REGISTER
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12),
            child: SvgPicture.asset(
              AppConstants.icons.user,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1
                    ? Colors.white
                    : const Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: isNormalLoggedIn ? 'Profile' : 'Register',
        ),

        /// 🔥 REELS
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12),
            child: SvgPicture.asset(
              AppConstants.icons.reels,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2
                    ? Colors.white
                    : const Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Reels',
        ),

        /// 🔥 ADS
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12),
            child: SvgPicture.asset(
              AppConstants.icons.ads,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3
                    ? Colors.white
                    : const Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Ads',
        ),

        /// 🔥 DONATERS
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12),
            child: SvgPicture.asset(
              AppConstants.icons.menu,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 4
                    ? Colors.white
                    : const Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'My Profile',
        ),
      ],
    );
  }
}
