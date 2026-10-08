import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/common_otp_field.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/models/vip_otp_model.dart';
import 'package:holynikkah/modules/registration/services/normal_otp_service.dart';
import 'package:holynikkah/modules/registration/services/vip_otp_service.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/registration/models/vip_user_fields.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _otpFieldKey = GlobalKey<CommonOtpFieldState>();
  String _otp = '';
  bool _hasOtpError = false;
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _isResending = false;
  String _phoneNumber = '';
  String _registrationType = 'vip';
  int? _retryAfterSeconds;
  Timer? _retryTimer;
  String? _statusMessage;

  static const Color _bgPrimary = Color(0xFF0E1F16);
  static const Color _bgGradientTop = Color(0xFF142B1F);
  static const Color _bgGradientBottom = Color(0xFF060D09);
  static const Color _goldLight = Color(0xFFF3D68A);
  static const Color _goldMain = Color(0xFFC9973F);
  static const Color _goldDark = Color(0xFF9E7428);
  static const Color _inputFill = Color(0xFF162E21);
  static const Color _inputActiveFill = Color(0xFF1C3A2A);
  static const Color _inputBorder = Color(0xFF28523C);
  static const Color _textMuted = Color(0xFF8FAEA0);

  bool get _isBlocked => _retryAfterSeconds != null && _retryAfterSeconds! > 0;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    final phone = await _storage.read(key: 'phone_number');
    final registrationType = await _storage.read(key: 'registration_type');

    if (!mounted) return;

    setState(() {
      _phoneNumber = phone ?? '';
      _registrationType = registrationType ?? 'vip';
    });
  }

  void _startRetryTimer(int seconds) {
    _retryTimer?.cancel();
    setState(() {
      _retryAfterSeconds = seconds;
      _statusMessage =
          'Too many failed attempts. Try again in $seconds seconds';
    });

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if ((_retryAfterSeconds ?? 0) <= 1) {
        timer.cancel();
        setState(() {
          _retryAfterSeconds = null;
          _statusMessage = null;
        });
      } else {
        setState(() {
          _retryAfterSeconds = (_retryAfterSeconds ?? 1) - 1;
          _statusMessage =
              'Too many failed attempts. Try again in $_retryAfterSeconds seconds';
        });
      }
    });
  }

  void _clearOtpField() {
    _otpFieldKey.currentState?.clear();
    _otp = '';
  }

  void _handleVerifyFailure(VipOtpVerifyData? data, String message) {
    setState(() => _hasOtpError = true);

    final displayMessage = data?.feedbackMessage(fallback: message) ?? message;

    if (data?.isLoginBlocked == true) {
      final retrySeconds = data?.retryAfterSeconds ?? 0;
      if (retrySeconds > 0) {
        _startRetryTimer(retrySeconds);
      } else {
        setState(() => _statusMessage = displayMessage);
      }
      _clearOtpField();
      CommonSnackBar.showError(context, displayMessage);
      return;
    }

    if (data?.isExpired == true) {
      setState(() => _statusMessage = displayMessage);
      _clearOtpField();
      CommonSnackBar.showError(context, displayMessage);
      return;
    }

    setState(() => _statusMessage = displayMessage);
    _clearOtpField();
    CommonSnackBar.showError(context, displayMessage);
  }

  Future<void> _handleVerifySuccess(VipOtpVerifyData data) async {
    final auth = context.read<AuthProvider>();
    final isVip = _registrationType.toLowerCase() == 'vip';

    if (data.loginSuccess) {
      final isCategorySelected = VipUserFields.isCategorySelected(data.user);
      if (isVip) {
        await auth.setVipLoggedIn(token: data.token, user: data.user);
        if (!mounted) return;
        await context.read<CategoryProvider>().applyVipCategoryFromUser(data.user);
        await auth.updateStoredVipCategorySelected(isCategorySelected);
        if (!mounted) return;
        await context.read<TemplateProvider>().applyVipTemplateFromUser(
          data.user,
        );
      } else {
        await auth.setNormalLoggedIn(token: data.token, user: data.user);
        if (!mounted) return;
        await context.read<CategoryProvider>().applyNormalCategoryFromUser(data.user);
        await auth.updateStoredNormalCategorySelected(isCategorySelected);
        if (!mounted) return;
        await context.read<TemplateProvider>().applyNormalTemplateFromUser(
          data.user,
        );
      }
      if (!mounted) return;
      if (data.user != null) {
        context.read<ProfileProvider>().applyUserData(data.user!, isVip: isVip);
      }
      CommonSnackBar.showSuccess(
        context,
        'OTP verified and login successful',
      );
      Navigator.of(context).pushReplacementNamed(Routes.home);
      return;
    }

    if (data.phoneVerified || (!data.userExists && data.verified)) {
      if (!mounted) return;
      CommonSnackBar.showSuccess(context, 'Phone verified successfully');
      Navigator.of(context).pushReplacementNamed(
        Routes.registration,
        arguments: {'isVip': isVip},
      );
      return;
    }

    if (!mounted) return;
    CommonSnackBar.showSuccess(context, 'OTP Verified');
    Navigator.of(context).pushReplacementNamed(
      Routes.registration,
      arguments: {'isVip': isVip},
    );
  }

  void _verifyOtp() async {
    if (_isLoading || _isBlocked) return;

    if (_phoneNumber.isEmpty) {
      CommonSnackBar.showError(context, 'Phone number not found');
      return;
    }

    if (_otp.isEmpty) {
      setState(() => _hasOtpError = true);
      CommonSnackBar.showError(context, 'Please enter OTP');
      return;
    }

    if (_otp.length != AppConstants.otpLength) {
      setState(() => _hasOtpError = true);
      CommonSnackBar.showError(
        context,
        'OTP must be ${AppConstants.otpLength} digits',
      );
      return;
    }

    setState(() {
      _hasOtpError = false;
      _statusMessage = null;
      _isLoading = true;
    });

    try {
      if (_registrationType.toLowerCase() == 'vip') {
        final response = await VipOtpService.instance.verifyOtp(
          phone: _phoneNumber,
          otp: _otp,
        );
        final data = response.data;

        if (!response.status || data?.verified != true) {
          if (!mounted) return;
          _handleVerifyFailure(
            data,
            response.message.isNotEmpty
                ? response.message
                : 'Verification failed. Please try again.',
          );
          return;
        }

        if (!mounted) return;
        await _handleVerifySuccess(data!);
        return;
      }

      final response = await NormalOtpService.instance.verifyOtp(
        phone: _phoneNumber,
        otp: _otp,
      );
      final data = response.data;

      if (!response.status || data?.verified != true) {
        if (!mounted) return;
        _handleVerifyFailure(
          data,
          response.message.isNotEmpty
              ? response.message
              : 'Verification failed. Please try again.',
        );
        return;
      }

      if (!mounted) return;
      await _handleVerifySuccess(data!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasOtpError = true);
      _clearOtpField();
      CommonSnackBar.showError(
        context,
        'Verification failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_phoneNumber.isEmpty) {
      CommonSnackBar.showError(context, 'Phone number not found');
      return;
    }

    if (_isResending || _isLoading || _isBlocked) return;

    setState(() => _isResending = true);

    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.resendOtp(
        _phoneNumber,
        type: _registrationType,
      );

      if (!mounted) return;

      if (result.success) {
        _retryTimer?.cancel();
        _clearOtpField();
        setState(() {
          _otp = '';
          _hasOtpError = false;
          _statusMessage = null;
          _retryAfterSeconds = null;
        });
        CommonSnackBar.showSuccess(context, result.message);
      } else {
        CommonSnackBar.showError(context, result.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVip = _registrationType.toLowerCase() == 'vip';
    final inputsDisabled = _isLoading || _isBlocked;

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
            child: SingleChildScrollView(
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
                          'Verification Code',
                          style: AppTypography.marcellus(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.marcellus(
                              color: _textMuted,
                              fontSize: 14.sp,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Please enter the 4-digit code sent to ',
                              ),
                              TextSpan(
                                text: _phoneNumber.isNotEmpty
                                    ? '+91 $_phoneNumber'
                                    : 'your phone number',
                                style: AppTypography.marcellus(
                                  color: _goldLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_statusMessage != null) ...[
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF5350)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFEF5350)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: const Color(0xFFEF5350),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _statusMessage!,
                                    style: AppTypography.marcellus(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFEF5350),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 36.h),

                  // OTP Input Boxes
                  Center(
                    child: IgnorePointer(
                      ignoring: inputsDisabled,
                      child: Opacity(
                        opacity: inputsDisabled ? 0.5 : 1,
                        child: CommonOtpField(
                          key: _otpFieldKey,
                          hasError: _hasOtpError,
                          fillColor: _inputFill,
                          activeFillColor: _inputActiveFill,
                          borderColor: _inputBorder,
                          activeBorderColor: _goldLight,
                          textColor: Colors.white,
                          cursorColor: _goldLight,
                          activeBoxShadow: [
                            BoxShadow(
                              color: _goldMain.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          onChanged: (otp) {
                            setState(() {
                              _otp = otp;
                              if (_hasOtpError) _hasOtpError = false;
                            });
                          },
                          onCompleted: (otp) {
                            _otp = otp;
                            _verifyOtp();
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Resend OTP / Countdown section
                  Center(
                    child: _isBlocked
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16.sp,
                                color: _textMuted,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Resend code in ${_retryAfterSeconds}s',
                                style: AppTypography.marcellus(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _isResending || _isLoading ? null : _resendOtp,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 16.w,
                              ),
                              child: _isResending
                                  ? SizedBox(
                                      height: 18.h,
                                      width: 18.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _goldLight,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Didn't receive code? ",
                                          style: AppTypography.marcellus(
                                            fontSize: 14.sp,
                                            color: _textMuted,
                                          ),
                                        ),
                                        Text(
                                          'Resend OTP',
                                          style: AppTypography.marcellus(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: _goldLight,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: _goldLight,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                  ),

                  SizedBox(height: 36.h),

                  // Verify OTP Action Button
                  GestureDetector(
                    onTap: inputsDisabled ? null : _verifyOtp,
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
                      child: _isLoading
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
                              'Verify OTP',
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
            ),
          ),
        ),
      ),
    );
  }
}

