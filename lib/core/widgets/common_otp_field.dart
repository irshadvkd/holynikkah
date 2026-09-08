import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';

class CommonOtpField extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;
  final bool hasError;
  final bool autoFocus;
  final Color? fillColor;
  final Color? activeFillColor;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? textColor;
  final Color? cursorColor;
  final Color? errorColor;
  final List<BoxShadow>? activeBoxShadow;

  const CommonOtpField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = AppConstants.otpLength,
    this.hasError = false,
    this.autoFocus = true,
    this.fillColor,
    this.activeFillColor,
    this.borderColor,
    this.activeBorderColor,
    this.textColor,
    this.cursorColor,
    this.errorColor,
    this.activeBoxShadow,
  });

  @override
  State<CommonOtpField> createState() => CommonOtpFieldState();
}

class CommonOtpFieldState extends State<CommonOtpField> {
  static const Color _defaultBrandPrimary = Color(0xFF032544);
  static const Color _defaultErrorColor = Color(0xFFEF5350);
  static const Color _defaultBorderDefault = Color(0xFFE0E0E0);
  static const Color _defaultFillDefault = Color(0xFFF7F7F7);
  static const Color _defaultFillActive = Color(0xFFEFE5E5);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _lastCompletedOtp;

  String get value => _controller.text;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CommonOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _lastCompletedOtp = null;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    _lastCompletedOtp = null;
    _focusNode.requestFocus();
    setState(() {});
  }

  void _onFocusChanged() => setState(() {});

  void _onTextChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final otp = _controller.text;
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      if (_lastCompletedOtp != otp) {
        _lastCompletedOtp = otp;
        _focusNode.unfocus();
        widget.onCompleted(otp);
      }
    } else {
      _lastCompletedOtp = null;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final focused = _focusNode.hasFocus;
    final activeIndex = text.length < widget.length ? text.length : widget.length - 1;

    final fillDefault = widget.fillColor ?? _defaultFillDefault;
    final fillActive = widget.activeFillColor ?? _defaultFillActive;
    final borderDefault = widget.borderColor ?? _defaultBorderDefault;
    final borderActive = widget.activeBorderColor ?? _defaultBrandPrimary;
    final textCol = widget.textColor ?? _defaultBrandPrimary;
    final cursorCol = widget.cursorColor ?? _defaultBrandPrimary;
    final errColor = widget.errorColor ?? _defaultErrorColor;

    return AutofillGroup(
      child: Semantics(
        label: 'Enter ${widget.length} digit verification code',
        textField: true,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 56.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.length, (index) {
                    final isFilled = index < text.length;
                    final isActive = focused && index == activeIndex;
                    final digit = isFilled ? text[index] : null;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: _OtpDigitBox(
                        digit: digit,
                        isActive: isActive,
                        isFilled: isFilled,
                        hasError: widget.hasError,
                        fillColor: fillDefault,
                        activeFillColor: fillActive,
                        borderColor: borderDefault,
                        activeBorderColor: borderActive,
                        textColor: textCol,
                        cursorColor: cursorCol,
                        errorColor: errColor,
                        activeBoxShadow: widget.activeBoxShadow,
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      maxLength: widget.length,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: _onTextChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  final String? digit;
  final bool isActive;
  final bool isFilled;
  final bool hasError;
  final Color fillColor;
  final Color activeFillColor;
  final Color borderColor;
  final Color activeBorderColor;
  final Color textColor;
  final Color cursorColor;
  final Color errorColor;
  final List<BoxShadow>? activeBoxShadow;

  const _OtpDigitBox({
    required this.digit,
    required this.isActive,
    required this.isFilled,
    required this.hasError,
    required this.fillColor,
    required this.activeFillColor,
    required this.borderColor,
    required this.activeBorderColor,
    required this.textColor,
    required this.cursorColor,
    required this.errorColor,
    this.activeBoxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final borderCol = hasError
        ? errorColor
        : isActive
            ? activeBorderColor
            : isFilled
                ? activeBorderColor.withValues(alpha: 0.5)
                : borderColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 56.w,
      height: 56.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? activeFillColor : fillColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: borderCol,
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: isActive
            ? (activeBoxShadow ??
                [
                  BoxShadow(
                    color: activeBorderColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ])
            : null,
      ),
      child: digit != null
          ? Text(
              digit!,
              style: AppTypography.marcellus(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1,
              ),
            )
          : isActive
              ? _BlinkingCursor(color: cursorColor)
              : null,
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
