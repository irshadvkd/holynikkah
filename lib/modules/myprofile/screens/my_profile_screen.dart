import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/myprofile/screens/my_profile_detail_screen.dart';
import 'package:holynikkah/modules/partner/screens/phone_requests_screen.dart';
import 'package:holynikkah/modules/template/screens/my_template_screen.dart';
import 'package:holynikkah/core/widgets/legal_screens.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isAnyUserLoggedIn) {
          context.read<ProfileProvider>().fetchProfiles(authProvider: auth);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final isLoggedIn = authProvider.isAnyUserLoggedIn;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Base Radial Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -1.0),
                  radius: 1.2,
                  colors: [
                    Color(0xFF101D33), // var(--bg-mid)
                    Color(0xFF0A1220), // var(--bg-deep)
                    Color(0xFF050810), // var(--bg-vignette)
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // 2. Tiled Animated Lattice pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LatticePainter(animationValue: _animationController.value),
                );
              },
            ),
          ),
          // 3. Lattice veil (inner gradient/vignette layer)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0A1220).withOpacity(0.12),
                    const Color(0xFF060A12).withOpacity(0.42),
                    const Color(0xFF050810).withOpacity(0.68),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // 4. Content Stage
          SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 24.h),
                if (authProvider.isVipLoggedIn && authProvider.isNormalLoggedIn) ...[
                  _buildProfileSelector(profileProvider),
                  SizedBox(height: 16.h),
                ],
                // Profile Card
                _buildProfileCard(context, profileProvider, isLoggedIn),
                SizedBox(height: 38.h),


                // Category group
                _buildCategoryGroup(context, isLoggedIn),
                SizedBox(height: 30.h),

                // ACCOUNT group
                _buildAccountGroup(context, isLoggedIn),
                SizedBox(height: 30.h),

                // SUPPORT group
                // _buildSupportGroup(context),
                // SizedBox(height: 30.h),

                // Logout
                if (isLoggedIn) _buildLogoutButton(context),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(ProfileProvider profileProvider) {
    final isVip = profileProvider.isVipProfile;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0E182A).withOpacity(0.58),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3C78F).withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                profileProvider.setVipProfile(true);
              },
              child: Container(
                height: 38.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: isVip
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFC9A15F), // brass
                            Color(0xFFE3C78F), // brass-soft
                          ],
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    'VIP Profile',
                    style: AppTypography.marcellus(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isVip ? const Color(0xFF0A1220) : const Color(0xFFCBB388).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                profileProvider.setVipProfile(false);
              },
              child: Container(
                height: 38.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: !isVip ? const Color(0xFF16264C) : null,
                  border: !isVip
                      ? Border.all(color: const Color(0xFFE3C78F).withOpacity(0.24))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Normal Profile',
                    style: AppTypography.marcellus(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: !isVip ? const Color(0xFFF4ECDD) : const Color(0xFFCBB388).withOpacity(0.8),
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

  Widget _buildProfileCard(
    BuildContext context,
    ProfileProvider profileProvider,
    bool isLoggedIn,
  ) {
    return GestureDetector(
      onTap: () {
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyProfileDetailScreen()),
          );
        } else {
          _showLoginPrompt(context);
        }
      },
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: const Color(0xFF0E182A).withOpacity(0.58),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFE3C78F).withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30.r,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            profileProvider.profileImagePath != null &&
                    profileProvider.profileImagePath!.isNotEmpty
                ? ClipOval(
                    child: profileProvider.isProfileImageNetwork
                        ? CustomNetworkImage(
                            url: profileProvider.profileImageNetworkUrl,
                            width: 64.w,
                            height: 64.h,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(profileProvider.profileImagePath!),
                            width: 64.w,
                            height: 64.h,
                            fit: BoxFit.cover,
                          ),
                  )
                : Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.4),
                        colors: [
                          Color(0xFFE3C78F), // var(--brass-soft)
                          Color(0xFFC9A15F), // var(--brass)
                        ],
                        stops: [0.0, 0.75],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(0, 6),
                          blurRadius: 18.r,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        '''<svg viewBox="0 0 24 24" fill="none">
                          <circle cx="12" cy="8" r="3.6" fill="#0a1220"/>
                          <path d="M4 20c0-4.2 3.6-7 8-7s8 2.8 8 7" fill="#0a1220"/>
                        </svg>''',
                        width: 28.w,
                        height: 28.h,
                      ),
                    ),
                  ),
            SizedBox(width: 18.w),
            // Fields
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Name',
                    style: AppTypography.marcellus(
                      fontSize: 12.sp,
                      letterSpacing: 0.12.w,
                      color: const Color(0xFFCBB388).withOpacity(0.62),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isLoggedIn
                        ? (profileProvider.name.isEmpty ? 'Add your name' : profileProvider.name)
                        : 'Guest User',
                    style: AppTypography.marcellus(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF4ECDD),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Id Number',
                    style: AppTypography.marcellus(
                      fontSize: 12.sp,
                      letterSpacing: 0.12.w,
                      color: const Color(0xFFCBB388).withOpacity(0.62),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isLoggedIn
                        ? (profileProvider.profileId.isEmpty
                            ? 'Add your ID'
                            : profileProvider.profileId)
                        : 'Please Login',
                    style: AppTypography.marcellus(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF4ECDD),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, bool isLoggedIn) {
    return _buildGroupSection(
      label: 'BROWSE BY CATEGORY',
      rows: [
        _buildRowItem(
          icon: Icons.description_outlined,
          title: 'Templates',
          desc: 'Design library',
          onTap: () {
            if (isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTemplateScreen()),
              );
            } else {
              _showLoginPrompt(context);
            }
          },
        ),
        _buildRowItem(
          icon: Icons.remove_red_eye_outlined,
          title: 'Viewers',
          desc: "Who's visiting",
          onTap: () {
            if (isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PhoneRequestsScreen()),
              );
            } else {
              _showLoginPrompt(context);
            }
          },
        ),
        // _buildRowItem(
        //   icon: Icons.bolt,
        //   title: 'Boost',
        //   desc: 'Get seen more',
        //   onTap: () {
        //     _showComingSoonSnackBar(context, 'Boost feature is coming soon!');
        //   },
        // ),
      ],
    );
  }

  Widget _buildAccountGroup(BuildContext context, bool isLoggedIn) {
    return _buildGroupSection(
      label: 'ACCOUNT',
      rows: [
        _buildRowItem(
          icon: Icons.notifications_none_outlined,
          title: 'Notifications',
          desc: 'Manage your alerts',
          onTap: () {
            _showComingSoonSnackBar(context, 'Notifications preferences will be active soon.');
          },
        ),
        _buildRowItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          desc: 'Control what others see',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
            );
          },
        ),
        _buildRowItem(
          icon: Icons.article_outlined,
          title: 'Terms & Conditions',
          desc: 'Read the fine print',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            );
          },
        ),
      ],
    );
  }

  // Widget _buildSupportGroup(BuildContext context) {
  //   return _buildGroupSection(
  //     label: 'SUPPORT',
  //     rows: [
  //       _buildRowItem(
  //         icon: Icons.diamond_outlined,
  //         title: 'Holynikah Ceremony',
  //         desc: 'Plan your ceremony details',
  //         onTap: () {
  //           _showComingSoonSnackBar(context, 'Ceremony planning dashboard is coming soon!');
  //         },
  //       ),
  //       _buildRowItem(
  //         icon: Icons.lightbulb_outline,
  //         title: 'Suggestions',
  //         desc: 'Help us improve Holynikah',
  //         onTap: () {
  //           _showComingSoonSnackBar(context, 'Suggestions feature is coming soon.');
  //         },
  //       ),
  //       _buildRowItem(
  //         icon: Icons.monetization_on_outlined,
  //         title: 'Donate',
  //         desc: 'Support the community',
  //         onTap: () {
  //           _showComingSoonSnackBar(context, 'Community donation portal is coming soon.');
  //         },
  //       ),
  //     ],
  //   );
  // }

  Widget _buildGroupSection({
    required String label,
    required List<Widget> rows,
  }) {
    List<Widget> childrenWithDividers = [];
    for (int i = 0; i < rows.length; i++) {
      childrenWithDividers.add(rows[i]);
      if (i < rows.length - 1) {
        childrenWithDividers.add(
          Divider(
            color: const Color(0xFFE3C78F).withOpacity(0.1),
            height: 1.h,
            thickness: 1.h,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16.w,
              height: 1.h,
              color: const Color(0xFFC9A15F).withOpacity(0.4),
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: AppTypography.marcellus(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.28.w,
                color: const Color(0xFFC9A15F),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0E182A).withOpacity(0.58),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFE3C78F).withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                offset: const Offset(0, 10),
                blurRadius: 30.r,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            children: childrenWithDividers,
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFC9A15F).withOpacity(0.4)),
                color: const Color(0xFFC9A15F).withOpacity(0.07),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFFC9A15F),
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.marcellus(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF4ECDD),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    desc,
                    style: AppTypography.marcellus(
                      fontSize: 14.sp,
                      color: const Color(0xFFCBB388).withOpacity(0.62),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 14.w),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFFCBB388).withOpacity(0.62),
              size: 17.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 64.w, vertical: 16.h),
            side: BorderSide(color: const Color(0xFFC9A15F).withOpacity(0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999.r),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFCBB388),
          ),
          onPressed: () => _logout(context),
          child: Text(
            'Logout',
            style: AppTypography.marcellus(
              fontSize: 19.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.06.w,
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101D33), // var(--bg-mid)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(color: Color(0x29E3C78F)), // var(--glass-edge)
        ),
        title: Text(
          'Join HolyNikah',
          style: AppTypography.marcellus(
            color: const Color(0xFFF4ECDD), // var(--cream)
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'To access this feature, please log in to your account.',
          style: AppTypography.marcellus(
            color: const Color(0xFFCBB388), // var(--champagne)
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: EdgeInsets.only(bottom: 20.h, left: 10.w, right: 10.w),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC9A15F), // var(--brass)
              foregroundColor: const Color(0xFF0A1220),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(type: 'vip'),
                ),
              );
            },
            child: Text(
              'VIP Login',
              style: AppTypography.marcellus(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFCBB388),
              side: const BorderSide(color: Color(0xFFCBB388)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(type: 'normal'),
                ),
              );
            },
            child: Text(
              'Normal Login',
              style: AppTypography.marcellus(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF101D33),
        content: Text(
          message,
          style: AppTypography.marcellus(
            color: const Color(0xFFF4ECDD),
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: const Color(0xFFC9A15F).withOpacity(0.3)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101D33), // var(--bg-mid)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(color: Color(0x29E3C78F)), // var(--glass-edge)
        ),
        title: Text(
          'Logout',
          style: AppTypography.marcellus(
            color: const Color(0xFFF4ECDD),
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.marcellus(
            color: const Color(0xFFCBB388),
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.marcellus(
                color: const Color(0xFFCBB388).withOpacity(0.7),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logoutAll();
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 2),
                ),
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: AppTypography.marcellus(
                color: Colors.redAccent,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LatticePainter extends CustomPainter {
  final double animationValue;
  const LatticePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFC9A15F).withOpacity(0.9 * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final innerStrokePaint = Paint()
      ..color = const Color(0xFFC9A15F).withOpacity(0.75 * 0.9 * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final dotPaint = Paint()
      ..color = const Color(0xFFC9A15F).withOpacity(0.8 * 0.42)
      ..style = PaintingStyle.fill;

    const double cellSize = 100.0;
    final double offset = animationValue * cellSize;

    final int cols = (size.width / cellSize).ceil() + 2;
    final int rows = (size.height / cellSize).ceil() + 2;

    canvas.save();
    canvas.translate(offset % cellSize, offset % cellSize);

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final double x = c * cellSize;
        final double y = r * cellSize;

        // Outer polygon (diamond)
        final path1 = Path()
          ..moveTo(x + 50, y + 0)
          ..lineTo(x + 100, y + 50)
          ..lineTo(x + 50, y + 100)
          ..lineTo(x + 0, y + 50)
          ..close();
        canvas.drawPath(path1, strokePaint);

        // Inner polygon
        final path2 = Path()
          ..moveTo(x + 50, y + 18)
          ..lineTo(x + 82, y + 50)
          ..lineTo(x + 50, y + 82)
          ..lineTo(x + 18, y + 50)
          ..close();
        canvas.drawPath(path2, innerStrokePaint);

        // Center dot
        canvas.drawCircle(Offset(x + 50, y + 50), 3.0, dotPaint);

        // Corner dot
        canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LatticePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}


