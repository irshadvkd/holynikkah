import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_otp_field.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/models/vip_otp_model.dart';
import 'package:holynikkah/modules/registration/services/normal_otp_service.dart';
import 'package:holynikkah/modules/registration/services/vip_otp_service.dart';
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
    final isVip = _registrationType == 'vip';

    if (data.loginSuccess) {
      if (isVip) {
        await auth.setVipLoggedIn(token: data.token, user: data.user);
        if (!mounted) return;
        await context.read<CategoryProvider>().applyVipCategoryFromUser(
          data.user,
        );
        if (!mounted) return;
        await context.read<TemplateProvider>().applyVipTemplateFromUser(
          data.user,
        );
      } else {
        await auth.setNormalLoggedIn(token: data.token, user: data.user);
        if (!mounted) return;
        await context.read<CategoryProvider>().applyNormalCategoryFromUser(
          data.user,
        );
        if (!mounted) return;
        await context.read<TemplateProvider>().applyNormalTemplateFromUser(
          data.user,
        );
      }
      if (!mounted) return;
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
      if (_registrationType == 'vip') {
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
    final inputsDisabled = _isLoading || _isBlocked;

    return CommonAppBar(
      title: "",
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 160.h),

            Text(
              'Verification Code',
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 12.h),

            Text(
              'Please Enter Verification Code sent to your phone number',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black),
            ),

            if (_statusMessage != null) ...[
              SizedBox(height: 12.h),
              Text(
                _statusMessage!,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF5350),
                ),
              ),
            ],

            SizedBox(height: 60.h),

            Center(
              child: IgnorePointer(
                ignoring: inputsDisabled,
                child: Opacity(
                  opacity: inputsDisabled ? 0.5 : 1,
                  child: CommonOtpField(
                    key: _otpFieldKey,
                    hasError: _hasOtpError,
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

            if (!_isBlocked)
              Center(
                child: TextButton(
                  onPressed: _isResending || _isLoading ? null : _resendOtp,
                  child: _isResending
                      ? SizedBox(
                          height: 18.h,
                          width: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Resend OTP',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),

            const Spacer(),

            Center(
              child: CommonButton(
                title: "Verify OTP",
                isLoading: _isLoading,
                onTap: inputsDisabled ? () {} : _verifyOtp,
              ),
            ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}
