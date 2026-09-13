import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_text_field.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// 📱 Preserved Phone OTP Login Form
/// Preserves the original phone number input + OTP send flow.
class OtpLoginForm extends StatefulWidget {
  final String type;

  const OtpLoginForm({super.key, required this.type});

  @override
  State<OtpLoginForm> createState() => _OtpLoginFormState();
}

class _OtpLoginFormState extends State<OtpLoginForm> {
  final _phoneController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  static const Color _bgPrimary = Color(0xFF0E1F16);
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
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
            SizedBox(height: 32.h),

            // Phone Number Input
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
              onTap: authProvider.isLoading ? null : _sendOtp,
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
          ],
        );
      },
    );
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      CommonSnackBar.showError(context, 'Please enter phone number');
      return;
    } else if (phone.length != 10) {
      CommonSnackBar.showError(context, 'Please enter 10 digit phone number');
      return;
    }

    await _storage.write(key: 'phone_number', value: phone);
    await _storage.write(key: 'registration_type', value: widget.type);

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
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
