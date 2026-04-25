import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';

class OtpInputField extends StatefulWidget {
  final Function(String) onCompleted;
  final int length;

  const OtpInputField({super.key, required this.onCompleted, this.length = 6});

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (_) => TextEditingController());
    focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in controllers) c.dispose();
    for (var f in focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    /// 🔥 HANDLE FULL OTP PASTE
    if (value.length > 1) {
      final chars = value.split('');

      for (int i = 0; i < chars.length && i < widget.length; i++) {
        controllers[i].text = chars[i];
      }

      focusNodes[widget.length - 1].requestFocus();
      _validateAndComplete();
      return;
    }

    /// 👉 Normal typing
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        focusNodes[index - 1].requestFocus();
      }
    }

    _validateAndComplete();
  }

  void _validateAndComplete() {
    String otp = controllers.map((e) => e.text).join();

    /// ❌ EMPTY
    if (otp.isEmpty) {
      return;
    }

    /// ❌ LESS THAN REQUIRED
    if (otp.length < widget.length) {
      return;
    }

    /// ❌ MORE THAN (edge case)
    if (otp.length > widget.length) {
      CommonSnackBar.showError(context, 'OTP must be ${widget.length} digits');
      return;
    }

    /// ✅ COMPLETE
    if (!_isCompleted) {
      _isCompleted = true;
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50.w,
          height: 50.h,
          child: RawKeyboardListener(
            focusNode: FocusNode(), // separate listener
            onKey: (event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {

                /// 🔥 If current box is empty → move back
                if (controllers[index].text.isEmpty && index > 0) {
                  focusNodes[index - 1].requestFocus();

                  /// also clear previous box
                  controllers[index - 1].clear();
                }
              }
            },
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],

              enableSuggestions: false,
              autocorrect: false,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,

              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.inputText,
              ),

              cursorColor: const Color(0xFF032544),

              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFEFE5E5),
                contentPadding: const EdgeInsets.only(bottom: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(
                    color: Color(0xFF032544),
                    width: 1.8,
                  ),
                ),
              ),

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onChanged(value, index),
            ),
          ),
        );
      }),
    );
  }
}
