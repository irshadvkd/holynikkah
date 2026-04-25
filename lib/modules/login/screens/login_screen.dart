import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/utils/utils.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_text_field.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
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

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      title: "",
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
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
                          color: Color(0xFF000000),
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
                        child: SvgPicture.asset(
                          "assets/icons/hide_password.svg",
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),
                    GestureDetector(
                      onTap: authProvider.isLoading ? () {} : _login,
                      child: Container(
                        width: 300.w,
                        height: 50.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.r),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF303036).withOpacity(.7),
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: authProvider.isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Text(
                                'Send OTP',
                                style: GoogleFonts.inter(
                                  color: Color(0xFF000000),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
    await _storage.write(key: 'registration_type', value: widget.type);

    final auth = context.read<AuthProvider>();

    // Prevent double tap by checking loading state
    if (auth.isLoading) return;

    final success = await auth.sendOtp(phone);

    if (success) {
      CommonSnackBar.showSuccess(context, 'OTP sent successfully');
      Navigator.of(context).pushNamed(Routes.verification);
    } else {
      CommonSnackBar.showError(context, 'Failed to send OTP');
    }
  }
}
