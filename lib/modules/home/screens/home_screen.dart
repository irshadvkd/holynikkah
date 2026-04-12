import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/services/category_session_storage.dart';
import 'package:holynikkah/core/services/home_session_storage.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/widgets/debug_navigation_fab.dart';
import 'package:holynikkah/modules/ads/screens/ads_screen.dart';
import 'package:holynikkah/modules/category/screens/vip_category_screen.dart';
import 'package:holynikkah/modules/donaters/screens/donaters_screen.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/partner/widgets/partner_full_screen_view.dart';
import 'package:holynikkah/modules/reels/screens/reels_screen.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final int? initialIndex;
  const HomeScreen({super.key, this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;
  bool _hasCheckedCategory = false;
  int? _lastInitialIndex;

  @override
  void initState() {
    super.initState();
    _lastInitialIndex = widget.initialIndex;
    _initSelectedIndex();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset category check if initialIndex changed
    if (widget.initialIndex != _lastInitialIndex) {
      _lastInitialIndex = widget.initialIndex;
      _hasCheckedCategory = false;
      _initSelectedIndex();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check category selection after dependencies are resolved
    if (!_hasCheckedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCategorySelection();
        _hasCheckedCategory = true;
      });
    }
  }

  Future<void> _initSelectedIndex() async {
    // If caller forces an initial tab (e.g. after registration), prefer it.
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
      await HomeSessionStorage().writeSelectedIndex(_selectedIndex);
      return;
    }

    // Otherwise restore last selected tab.
    final storedIndex = await HomeSessionStorage().readSelectedIndex();
    if (!mounted) return;
    if (storedIndex != null && storedIndex >= 0 && storedIndex <= 4) {
      setState(() {
        _selectedIndex = storedIndex;
      });
    }
  }

  Future<void> _checkCategorySelection() async {
    AppLogger.info("Checking category selection for index $_selectedIndex", tag: "HomeScreen");
    if (_selectedIndex == 0) {
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      AppLogger.info("User logged in: $isLoggedIn", tag: "HomeScreen");
      if (isLoggedIn) {
        final isCategorySelected = await CategorySessionStorage().isCategorySelected();
        AppLogger.info("Category selected: $isCategorySelected", tag: "HomeScreen");
        if (!isCategorySelected && mounted) {
          AppLogger.info("Showing VipCategoryScreen", tag: "HomeScreen");
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VipCategoryScreen(
                onNavigate: (newIndex) {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedIndex = newIndex;
                  });
                  HomeSessionStorage().writeSelectedIndex(newIndex);
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    AppLogger.info("HomeScreen build, isLoggedIn: $isLoggedIn", tag: "HomeScreen");
    
    // Check category selection when user is logged in and on index 0
    if (isLoggedIn && _selectedIndex == 0 && !_hasCheckedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCategorySelection();
        _hasCheckedCategory = true;
      });
    }
    
    final screens = <Widget>[
      if (isLoggedIn)
        PartnerFullScreenView(
          imageUrls: [
            'assets/sample/partner1.png',
            'assets/sample/partner2.png',
            'assets/sample/partner3.png',
            'assets/sample/partner4.png',
          ],
        )
      else
        const LoginPage(type: "vip"),
      const LoginPage(type: "normal"),
      const ReelsScreen(),
      const AdsScreen(),
      const DonatersScreen(),
    ];
    AppLogger.info("Selected screen index: $_selectedIndex", tag: "HomeScreen");

    return Scaffold(
      appBar: null,
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    AppLogger.info("Building bottom nav, isLoggedIn: $isLoggedIn", tag: "HomeScreen");
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xFF616161).withAlpha(240),
      selectedFontSize: 10.sp,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600, // SemiBold
        height: 1.0, // line-height: 100%
        letterSpacing: 0,
      ),
      unselectedFontSize: 10.sp,
      currentIndex: _selectedIndex,
      onTap: (index) async {
        // Reset category check flag when navigating away from index 0
        if (_selectedIndex == 0 && index != 0) {
          _hasCheckedCategory = false;
        }
        
        // Check if navigating to index 0, user is logged in, and category not selected
        if (index == 0) {
          final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
          if (isLoggedIn) {
            final isCategorySelected = await CategorySessionStorage().isCategorySelected();
            if (!isCategorySelected) {
              // Push VipCategoryScreen instead of changing tab
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VipCategoryScreen(
                      onNavigate: (newIndex) {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedIndex = newIndex;
                        });
                        HomeSessionStorage().writeSelectedIndex(newIndex);
                      },
                    ),
                  ),
                );
              }
              return;
            }
          }
        }
        
        setState(() {
          _selectedIndex = index;
        });
        await HomeSessionStorage().writeSelectedIndex(index);
      },
      items: [
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8),
            child: SvgPicture.asset(
              AppConstants.icons.vipRegister,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0
                    ? Colors.white
                    : Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: isLoggedIn ? 'Profile' : 'Vip Register',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8),
            child: SvgPicture.asset(
              AppConstants.icons.user,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1
                    ? Colors.white
                    : Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Register',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8),
            child: SvgPicture.asset(
              AppConstants.icons.reels,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2
                    ? Colors.white
                    : Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Reels',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8),
            child: SvgPicture.asset(
              AppConstants.icons.ads,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3
                    ? Colors.white
                    : Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Ads',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8),
            child: SvgPicture.asset(
              AppConstants.icons.donate,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 4
                    ? Colors.white
                    : Color(0xFF616161).withAlpha(240),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: 'Donaters',
        ),
      ],
    );
  }
}
