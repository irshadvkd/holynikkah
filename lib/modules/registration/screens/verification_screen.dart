import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
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

    /// ✅ SUCCESS - Mark user as logged in
    await context.read<AuthProvider>().setLoggedIn();
    CommonSnackBar.showSuccess(context, 'OTP Verified');

    // Read the registration type stored during login
    final registrationType = await _storage.read(key: 'registration_type') ?? 'vip';
    final isVip = registrationType == 'vip';

    /// 🚀 AUTO ROUTE NAVIGATION (CORRECT WAY)
    context.router.replace(
      RegistrationRoute(
        isVip: isVip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
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
                color: Colors.white,
              ),
            ),

            SizedBox(height: 12.h),

            /// 🔹 Subtitle
            Text(
              'Please Enter Verification Code sent to your phone number',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
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

            /// 🔹 VERIFY BUTTON
            GestureDetector(
              onTap: _verifyOtp,
              child: Container(
                height: 55.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Verify OTP',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}
