import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';

enum TextFieldType {
  name,
  email,
  phone,
  password,
  confirmPassword,
  age,
  pinCode,
  numeric,
  decimal,
  url,
  general,
}

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextFieldType type;
  final String? Function(String?)? customValidator;
  final List<TextInputFormatter>? customFormatters;
  final bool isRequired;
  final String? fieldName;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final String? confirmPasswordValue; // For confirm password validation
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextCapitalization? textCapitalization;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.type = TextFieldType.general,
    this.customValidator,
    this.customFormatters,
    this.isRequired = true,
    this.fieldName,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.confirmPasswordValue,
    this.onTap,
    this.onChanged,
    this.textCapitalization,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAliasWithSaveLayer,
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
      child: TextFormField(
        controller: widget.controller,
        validator: _getValidator(),
        inputFormatters: _getInputFormatters(),
        keyboardType: _getKeyboardType(),
        obscureText: _obscureText,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          color: Colors.black87,
        ),
        textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: _getSuffixIcon(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide(
              color: const Color(0xFF032544),
              width: 2.w,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2.w,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2.w,
            ),
          ),
          counterText: '', // Hide character counter
        ),
      ),
    );
  }

  String? Function(String?)? _getValidator() {
    if (widget.customValidator != null) {
      return widget.customValidator;
    }

    switch (widget.type) {
      case TextFieldType.name:
        return ValidationUtils.validateName;
      case TextFieldType.email:
        return ValidationUtils.validateEmail;
      case TextFieldType.phone:
        return ValidationUtils.validatePhone;
      case TextFieldType.password:
        return ValidationUtils.validatePassword;
      case TextFieldType.confirmPassword:
        return (value) => ValidationUtils.validateConfirmPassword(
              value,
              widget.confirmPasswordValue,
            );
      case TextFieldType.age:
        return ValidationUtils.validateAge;
      case TextFieldType.pinCode:
        return ValidationUtils.validatePinCode;
      case TextFieldType.numeric:
        return (value) => ValidationUtils.validateNumeric(
              value,
              fieldName: widget.fieldName,
            );
      case TextFieldType.url:
        return ValidationUtils.validateUrl;
      case TextFieldType.general:
        return widget.isRequired
            ? (value) => ValidationUtils.validateRequired(
                  value,
                  fieldName: widget.fieldName,
                )
            : null;
      case TextFieldType.decimal:
        return (value) => ValidationUtils.validateNumeric(
              value,
              fieldName: widget.fieldName,
            );
      default:
        return null;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (widget.customFormatters != null) {
      return widget.customFormatters!;
    }

    switch (widget.type) {
      case TextFieldType.name:
        return InputFormatters.nameFormatter();
      case TextFieldType.email:
        return InputFormatters.emailFormatter();
      case TextFieldType.phone:
        return InputFormatters.phoneFormatter();
      case TextFieldType.age:
        return InputFormatters.ageFormatter();
      case TextFieldType.pinCode:
        return InputFormatters.pinCodeFormatter();
      case TextFieldType.numeric:
        return InputFormatters.numericFormatter(maxLength: widget.maxLength);
      case TextFieldType.decimal:
        return InputFormatters.decimalFormatter(maxLength: widget.maxLength);
      default:
        return [];
    }
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    switch (widget.type) {
      case TextFieldType.email:
        return TextInputType.emailAddress;
      case TextFieldType.phone:
        return TextInputType.phone;
      case TextFieldType.numeric:
      case TextFieldType.age:
      case TextFieldType.pinCode:
        return TextInputType.number;
      case TextFieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case TextFieldType.url:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  Widget? _getSuffixIcon() {
    if (widget.type == TextFieldType.password ||
        widget.type == TextFieldType.confirmPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}