import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_text_field.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🧭 Login Screen
class LoginScreen extends StatefulWidget {
  final String type;
  const LoginScreen({super.key, required this.type});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  static const Color _bgPrimary = Color(0xFF0E1F16);
  static const Color _bgGradientTop = Color(0xFF142B1F);
  static const Color _bgGradientBottom = Color(0xFF060D09);
  static const Color _goldLight = Color(0xFFF3D68A);
  static const Color _goldMain = Color(0xFFC9973F);
  static const Color _goldDark = Color(0xFF9E7428);
  static const Color _inputFill = Color(0xFF162E21);
  static const Color _inputBorder = Color(0xFF28523C);
  static const Color _textMuted = Color(0xFF8FAEA0);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVip = widget.type.toLowerCase() == 'vip';

    return Scaffold(
      backgroundColor: _bgPrimary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bgGradientTop,
                _bgPrimary,
                _bgGradientBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 8.h),
                      // Top Back Navigation
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
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _goldLight,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Logo & Ambient Branding Container
                      Image.asset(
                        AppConstants.icons.logoHorizontal,
                        width: 300.w,
                        fit: BoxFit.contain,
                      ),

                      if (isVip) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_goldLight, _goldMain],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: _goldMain.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 14.sp,
                                color: _bgPrimary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'VIP ACCESS',
                                style: AppTypography.marcellus(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _bgPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 48.h),

                      // Form Content Box
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to Join',
                              style: AppTypography.marcellus(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Enter your mobile number to receive an OTP verification code.',
                              style: AppTypography.marcellus(
                                color: _textMuted,
                                fontSize: 14.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Custom Phone Number Text Field
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter 10-digit phone number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: InputFormatters.phoneFormatter(),
                        maxLength: 10,
                        maxLines: 1,
                        backgroundColor: _inputFill,
                        borderColor: _inputBorder,
                        textColor: Colors.white,
                        hintColor: _textMuted,
                        cursorColor: _goldLight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20.w, right: 12.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+91',
                                style: AppTypography.marcellus(
                                  color: _goldLight,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                width: 1,
                                height: 20.h,
                                color: _inputBorder,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 36.h),

                      // Send OTP Action Button
                      GestureDetector(
                        onTap: authProvider.isLoading ? null : _login,
                        child: Container(
                          width: double.infinity,
                          height: 52.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            gradient: const LinearGradient(
                              colors: [
                                _goldLight,
                                _goldMain,
                                _goldDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _goldMain.withValues(alpha: 0.4),
                                offset: const Offset(0, 6),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: 22.h,
                                  width: 22.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _bgPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Send OTP',
                                  style: AppTypography.marcellus(
                                    color: _bgPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 36.h),

                      // Bottom Trust/Security Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _textMuted.withValues(alpha: 0.7),
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Secured with HolyNikah Verification',
                            style: AppTypography.marcellus(
                              color: _textMuted.withValues(alpha: 0.7),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      CommonSnackBar.showError(context, 'Please enter phone number');
      return;
    } else if (phone.length != 10) {
      CommonSnackBar.showError(context, 'Please enter 10 digit phone number');
      return;
    }

    await _storage.write(key: 'phone_number', value: phone);
    // Store the registration type for verification screens
    await _storage.write(key: 'registration_type', value: widget.type);

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Prevent double tap by checking loading state
    if (auth.isLoading) return;

    final result = await auth.sendOtp(phone, type: widget.type);

    if (!mounted) return;

    if (result.success) {
      CommonSnackBar.showSuccess(context, result.message);
      Navigator.of(context).pushNamed(Routes.verification);
    } else {
      CommonSnackBar.showError(context, result.message);
    }
  }
}
