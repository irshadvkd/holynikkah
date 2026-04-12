import 'package:flutter/services.dart';

class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (value.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    final phoneRegex = RegExp(r'^[0-9]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password cannot exceed 128 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase and number';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 18) {
      return 'Age must be at least 18 years';
    }
    if (age > 100) {
      return 'Please enter a valid age';
    }
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // Dropdown validation
  static String? validateDropdown(dynamic value, {String? fieldName}) {
    if (value == null) {
      return '${fieldName ?? 'Please select an option'}';
    }
    return null;
  }

  // Custom length validation
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (minLength != null && value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }
    if (maxLength != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} cannot exceed $maxLength characters';
    }
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }
    return null;
  }

  // Indian PIN code validation
  static String? validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN code is required';
    }
    if (value.length != 6) {
      return 'PIN code must be 6 digits';
    }
    final pinRegex = RegExp(r'^[1-9][0-9]{5}$');
    if (!pinRegex.hasMatch(value)) {
      return 'Please enter a valid PIN code';
    }
    return null;
  }
}

class InputFormatters {
  // Phone number formatter (digits only)
  static List<TextInputFormatter> phoneFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(15),
    ];
  }

  // Name formatter (letters and spaces only)
  static List<TextInputFormatter> nameFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      LengthLimitingTextInputFormatter(50),
    ];
  }

  // Email formatter (basic email characters)
  static List<TextInputFormatter> emailFormatter() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
      LengthLimitingTextInputFormatter(100),
    ];
  }

  // Numeric formatter (numbers only)
  static List<TextInputFormatter> numericFormatter({int? maxLength}) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // Decimal formatter (numbers with decimal point)
  static List<TextInputFormatter> decimalFormatter({int? maxLength}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // PIN code formatter
  static List<TextInputFormatter> pinCodeFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ];
  }

  // Age formatter
  static List<TextInputFormatter> ageFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ];
  }

  // Alphabetic formatter (letters only)
  static List<TextInputFormatter> alphabeticFormatter({int? maxLength}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // Alphanumeric formatter
  static List<TextInputFormatter> alphanumericFormatter({int? maxLength}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // Information formatter (text with basic punctuation)
  static List<TextInputFormatter> informationFormatter({int? maxLength}) {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.,!?\-()\[\]"\n]')),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // Custom formatter
  static List<TextInputFormatter> customFormatter({
    required String pattern,
    int? maxLength,
  }) {
    return [
      FilteringTextInputFormatter.allow(RegExp(pattern)),
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
    ];
  }
}