import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/services/navigation_guard.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_text_field.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🧭 Login Screen
class LoginScreen extends StatefulWidget {
  final String? type;
  const LoginScreen({super.key, this.type});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ready to Join',
                    style: GoogleFonts.inter(
                      color: Color(0xFFF5F5F5),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 100.h),
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: InputFormatters.phoneFormatter(),
                  maxLength: 10,
                  maxLines: 1,
                  suffixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: SvgPicture.asset("assets/icons/hide_password.svg"),
                  ),
                ),
                SizedBox(height: 48.h),
                // SizedBox(
                //   width: double.infinity,
                //   height: 50.h,
                //   child: ElevatedButton(
                //     onPressed: _isLoading ? null : _login,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.amber,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(25.r),
                //       ),
                //     ),
                //     child: _isLoading
                //         ? const CircularProgressIndicator(color: Colors.black)
                //         : Text(
                //             'Login',
                //             style: GoogleFonts.inter(
                //               color: Colors.black,
                //               fontSize: 16.sp,
                //             ),
                //           ),
                //   ),
                // ),
                GradientBorderContainer(
                  borderRadius: 25.r,
                  onTap: () {
                    _login();
                  },
                  child: Text(
                    'Sent OTP',
                    style: GoogleFonts.inter(
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    // Store the registration type for verification screen
    await _storage.write(key: 'registration_type', value: widget.type ?? 'vip');

    final auth = context.read<AuthProvider>();

    /// 🔥 Changed here
    final success = await auth.sendOtp(phone);

    if (success) {
      CommonSnackBar.showSuccess(context, 'OTP sent successfully');

      await context.navigationGuard.navigateTo(
        context,
        const VerificationRoute(),
        trigger: 'login_otp_sent',
      );
    } else {
      CommonSnackBar.showError(context, 'Failed to send OTP');
    }
  }
}
