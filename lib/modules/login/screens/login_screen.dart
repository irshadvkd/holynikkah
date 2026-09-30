import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/legal_screens.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/login/widgets/google_logo_icon.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:provider/provider.dart';

/// 🧭 Login Screen
class LoginScreen extends StatefulWidget {
  final String type;
  final bool? showBackButton;

  const LoginScreen({
    super.key,
    required this.type,
    this.showBackButton,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 🌟 Smooth Logo Top-to-Bottom Slide + Fade-In Animation
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _logoAnimController,
      curve: Curves.easeOutCubic,
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _logoAnimController.forward();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    super.dispose();
  }

  // Premium Theme Palette matching HTML design
  static const Color _gold = Color(0xFFC9A35C);
  static const Color _cream = Color(0xFFF3EAD9);
  static const Color _creamDim = Color(0xFFCDBFA4);

  @override
  Widget build(BuildContext context) {
    final isVip = widget.type.toLowerCase() == 'vip';
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = widget.showBackButton ?? canPop;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.darkGreenGradient,
          ),
          child: SafeArea(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 34.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Top Back Navigation (if applicable)
                                SizedBox(height: 8.h),
                                if (shouldShowBack)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: _gold,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(height: 12.h),

                                const Spacer(flex: 2),

                                // 🌟 Animated Logo Container (Slide down from Top + Fade-In)
                                SlideTransition(
                                  position: _logoSlideAnimation,
                                  child: FadeTransition(
                                    opacity: _logoFadeAnimation,
                                    child: Image.asset(
                                      AppConstants.icons.logoVertical,
                                      width: 200.w,
                                      height: 200.h,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 52.h,
                                  child: isVip
                                      ? Center(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 5.h,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.goldGradient,
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.goldMain
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .workspace_premium_rounded,
                                                  size: 14.sp,
                                                  color: AppColors.onPrimary,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  'VIP ACCESS',
                                                  style: AppTypography.marcellus(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.onPrimary,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : null,
                                ),

                                // 🌟 Headline: Welcome to HolyNikah
                                Text(
                                  'Welcome to HolyNikah',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cormorantGaramond(
                                    color: _cream,
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    letterSpacing: 0.3,
                                  ),
                                ),

                                SizedBox(height: 14.h),

                                // 🌟 Subtitle: Great people find sacred souls
                                Text(
                                  'Great people find sacred souls',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cormorantGaramond(
                                    color: _creamDim,
                                    fontSize: 18.sp,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.4,
                                  ),
                                ),

                                SizedBox(height: 26.h),

                                // 🌟 Divider (34px x 1px gold hairline)
                                Container(
                                  width: 34.w,
                                  height: 1.h,
                                  color: _gold.withValues(alpha: 0.55),
                                ),

                                SizedBox(height: 56.h),

                                // 🔥 Continue with Google Button (CommonButton)
                                CommonButton(
                                  title: 'Continue with Google',
                                  isLoading: authProvider.isLoading,
                                  onTap: _handleGoogleSignIn,
                                  height: 54.h,
                                  borderRadius: BorderRadius.circular(30.r),
                                  backgroundColor: _gold,
                                  hasShadow: false,
                                  loaderColor: const Color(0xFF0E2019),
                                  prefixIcon: const GoogleLogoIcon(size: 20),
                                  textStyle: GoogleFonts.cormorantGaramond(
                                    color: const Color(0xFF0E2019),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18.sp,
                                    letterSpacing: 0.6,
                                  ),
                                ),

                                /*
                                // Previous custom button implementation (commented out)
                                GestureDetector(
                                  onTap: authProvider.isLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 17.h,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(30.r),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          _goldLight,
                                          _gold,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _gold.withValues(alpha: 0.28),
                                          blurRadius: 28,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: authProvider.isLoading
                                        ? SizedBox(
                                            height: 22.h,
                                            width: 22.w,
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(0xFF0E2019),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              GoogleLogoIcon(size: 20.w),
                                              SizedBox(width: 12.w),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts
                                                    .cormorantGaramond(
                                                  color:
                                                      const Color(0xFF0E2019),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18.sp,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                */

                                SizedBox(height: 26.h),

                                // 📜 Legal Footer
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'By continuing, you agree to our',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cormorantGaramond(
                                        color:
                                            _creamDim.withValues(alpha: 0.75),
                                        fontSize: 13.5.sp,
                                        letterSpacing: 0.3,
                                        height: 1.7,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const TermsScreen(),
                                              ),
                                            );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: _gold.withValues(
                                                      alpha: 0.4),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            padding:
                                                EdgeInsets.only(bottom: 1.h),
                                            child: Text(
                                              'Terms of Service',
                                              style: GoogleFonts
                                                  .cormorantGaramond(
                                                color: _gold,
                                                fontSize: 13.5.sp,
                                                letterSpacing: 0.3,
                                                height: 1.7,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                          ),
                                          child: Text(
                                            '·',
                                            style: GoogleFonts
                                                .cormorantGaramond(
                                              color: _creamDim
                                                  .withValues(alpha: 0.6),
                                              fontSize: 13.5.sp,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyScreen(),
                                              ),
                                            );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: _gold.withValues(
                                                      alpha: 0.4),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            padding:
                                                EdgeInsets.only(bottom: 1.h),
                                            child: Text(
                                              'Privacy Policy',
                                              style: GoogleFonts
                                                  .cormorantGaramond(
                                                color: _gold,
                                                fontSize: 13.5.sp,
                                                letterSpacing: 0.3,
                                                height: 1.7,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Spacer(flex: 3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;

    final isVip = widget.type.toLowerCase() == 'vip';
    final result = await auth.signInWithGoogle(type: widget.type);

    if (!mounted) return;

    if (result.cancelled) {
      return;
    }

    if (result.success) {
      if (result.isAlreadyRegistered) {
        // User already has an account -> Sync categories/templates & navigate to Home
        if (result.backendUserData != null) {
          if (isVip) {
            await context
                .read<CategoryProvider>()
                .setVipSelected(true);
            await context
                .read<AuthProvider>()
                .updateStoredVipCategorySelected(true);
            if (!mounted) return;
            await context
                .read<TemplateProvider>()
                .applyVipTemplateFromUser(result.backendUserData);
          } else {
            await context
                .read<CategoryProvider>()
                .setNormalSelected(true);
            await context
                .read<AuthProvider>()
                .updateStoredNormalCategorySelected(true);
            if (!mounted) return;
            await context
                .read<TemplateProvider>()
                .applyNormalTemplateFromUser(result.backendUserData);
          }
          if (!mounted) return;
          context.read<ProfileProvider>().applyUserData(
                result.backendUserData!,
                isVip: isVip,
              );
        }
        if (!mounted) return;
        CommonSnackBar.showSuccess(context, 'Login successful');
        Navigator.of(context).pushReplacementNamed(Routes.home);
      } else {
        // User not registered -> Navigate to Register with prefill data from other tier if available
        final prefill = result.prefillData;
        final prefillName =
            prefill?['name']?.toString() ?? result.user?.displayName;
        final prefillPhone = prefill?['phone']?.toString();

        CommonSnackBar.showSuccess(
            context, 'Google verified. Complete your profile.');
        Navigator.of(context).pushNamed(
          Routes.registration,
          arguments: {
            'isVip': isVip,
            'email': result.user?.email,
            'phoneNumber': prefillPhone,
            'name': prefillName,
            'prefillData': prefill,
          },
        );
      }
    } else {
      CommonSnackBar.showError(context, result.message);
    }
  }
}
