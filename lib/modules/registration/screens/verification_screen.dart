import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/widgets/otp_input_field.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  /// 🔥 Store OTP here
  String _otp = '';
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  /// 🔥 Validate + Navigate
  void _verifyOtp() async {
    /// ❌ EMPTY
    if (_otp.isEmpty) {
      CommonSnackBar.showError(context, 'Please enter OTP');
      return;
    }

    /// ❌ INVALID
    if (_otp.length != 6) {
      CommonSnackBar.showError(context, 'OTP must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /// Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      /// ✅ SUCCESS - Mark user as logged in
      // await context.read<AuthProvider>().setLoggedIn();
      CommonSnackBar.showSuccess(context, 'OTP Verified');

      // Read the registration type stored during login
      final registrationType = await _storage.read(key: 'registration_type');
      final isVip = registrationType == 'vip';

      Navigator.of(
        context,
      ).pushReplacementNamed(Routes.registration, arguments: {'isVip': isVip});
    } catch (e) {
      CommonSnackBar.showError(
        context,
        'Verification failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      title: "",
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 160.h),

            /// 🔹 Title
            Text(
              'Verification Code',
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 12.h),

            /// 🔹 Subtitle
            Text(
              'Please Enter Verification Code sent to your phone number',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black),
            ),

            SizedBox(height: 60.h),

            /// 🔹 OTP INPUT
            OtpInputField(
              length: 6,
              onCompleted: (otp) {
                _otp = otp;
                _verifyOtp();
              },
            ),

            const Spacer(),

            Center(
              child: CommonButton(
                title: "Verify OTP",
                isLoading: _isLoading,
                onTap: _verifyOtp,
              ),
            ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}
