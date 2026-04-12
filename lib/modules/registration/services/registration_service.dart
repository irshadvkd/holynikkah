import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/models/registration_model.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';

class RegistrationService {
  RegistrationService._();
  static final RegistrationService instance = RegistrationService._();

  Future<List<Categories>> getCategories(String type) async {
    try {
      AppLogger.info("Loading categories", tag: "RegistrationService");
      String response = "";
      if (type == 'vip') {
        response = await rootBundle.loadString('assets/data/vip_category.json');
      } else if (type == 'normal') {
        response = await rootBundle.loadString(
          'assets/data/normal_category.json',
        );
      }
      // response = await rootBundle.loadString(
      //   'assets/data/registration_categories.json',
      // );
      // final String response = await rootBundle.loadString(
      //   'assets/data/registration_categories.json',
      // );
      final data = json.decode(response);

      final jsonData = CategoryModel.fromJson(data);

      final categories = jsonData.categories ?? [];

      AppLogger.success(
        "Categories loaded: ${categories.length}",
        tag: "RegistrationService",
      );
      return categories;
    } catch (e) {
      AppLogger.error(
        "Failed to load categories: $e",
        tag: "RegistrationService",
      );
      return [];
    }
  }

  Future<bool> sendOtp(String phoneNumber) async {
    AppLogger.info("Sending OTP to $phoneNumber", tag: "RegistrationService");
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success
    AppLogger.success("OTP sent to $phoneNumber", tag: "RegistrationService");
    return true;
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    AppLogger.info(
      "Verifying OTP for $phoneNumber",
      tag: "RegistrationService",
    );
    await Future.delayed(const Duration(seconds: 1));

    // Simulate verification (accept any 6-digit OTP)
    final isValid = otp.length == 6;

    if (isValid) {
      AppLogger.success(
        "OTP verified for $phoneNumber",
        tag: "RegistrationService",
      );
    } else {
      AppLogger.warning(
        "Invalid OTP for $phoneNumber",
        tag: "RegistrationService",
      );
    }

    return isValid;
  }

  Future<bool> submitRegistration(RegistrationModel registration) async {
    AppLogger.info(
      "Submitting registration for ${registration.name}",
      tag: "RegistrationService",
    );
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success
    AppLogger.success(
      "Registration submitted for ${registration.name}",
      tag: "RegistrationService",
    );
    return true;
  }
}
