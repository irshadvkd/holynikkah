import 'package:flutter/material.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/widgets/common_otp_field.dart';

/// Backward-compatible alias for [CommonOtpField].
class OtpInputField extends StatelessWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;
  final bool hasError;
  final bool autoFocus;

  const OtpInputField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = AppConstants.otpLength,
    this.hasError = false,
    this.autoFocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonOtpField(
      onCompleted: onCompleted,
      onChanged: onChanged,
      length: length,
      hasError: hasError,
      autoFocus: autoFocus,
    );
  }
}
