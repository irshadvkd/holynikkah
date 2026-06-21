import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/models/registration_model.dart';
import 'package:holynikkah/modules/registration/services/normal_otp_service.dart';
import 'package:holynikkah/modules/registration/services/vip_otp_service.dart';

class RegistrationService {
  RegistrationService._();
  static final RegistrationService instance = RegistrationService._();

  Future<List<Categories>> getCategories(String type) async {
    if (type == 'vip') {
      return _getVipCategories();
    }

    return _getNormalCategories();
  }

  Future<List<Categories>> _getVipCategories() async {
    AppLogger.info('Fetching VIP categories', tag: 'RegistrationService');

    final response = await ApiClient.instance.get<List<Categories>>(
      AppConstants.urls.vipCategories,
      parser: CategoriesResponse.parseCategories,
    );

    if (response.success && response.data != null) {
      AppLogger.success(
        'VIP categories loaded: ${response.data!.length}',
        tag: 'RegistrationService',
      );
      return response.data!;
    }

    AppLogger.warning(
      'VIP categories API failed: ${response.message}. Falling back to local data.',
      tag: 'RegistrationService',
    );
    return _getLocalCategories('vip');
  }

  Future<List<Categories>> _getNormalCategories() async {
    AppLogger.info('Fetching normal categories', tag: 'RegistrationService');

    final response = await ApiClient.instance.get<List<Categories>>(
      AppConstants.urls.categories,
      parser: CategoriesResponse.parseCategories,
    );

    if (response.success && response.data != null) {
      AppLogger.success(
        'Normal categories loaded: ${response.data!.length}',
        tag: 'RegistrationService',
      );
      return response.data!;
    }

    AppLogger.warning(
      'Normal categories API failed: ${response.message}. Falling back to local data.',
      tag: 'RegistrationService',
    );
    return _getLocalCategories('normal');
  }

  Future<List<Categories>> _getLocalCategories(String type) async {
    try {
      AppLogger.info('Loading categories', tag: 'RegistrationService');
      final assetPath = type == 'normal'
          ? 'assets/data/normal_category.json'
          : 'assets/data/vip_category.json';
      final response = await rootBundle.loadString(assetPath);
      final data = json.decode(response);
      final jsonData = CategoryModel.fromJson(data);
      final categories = jsonData.categories ?? [];

      AppLogger.success(
        'Categories loaded: ${categories.length}',
        tag: 'RegistrationService',
      );
      return categories;
    } catch (e) {
      AppLogger.error(
        'Failed to load categories: $e',
        tag: 'RegistrationService',
      );
      return [];
    }
  }

  Future<bool> sendOtp(String phoneNumber, {bool isVip = false}) async {
    if (isVip) {
      final response = await VipOtpService.instance.sendOtp(phoneNumber);
      return response.status && (response.data?.otpSent ?? false);
    }

    final response = await NormalOtpService.instance.sendOtp(phoneNumber);
    return response.status && (response.data?.otpSent ?? false);
  }

  Future<bool> resendOtp(String phoneNumber, {bool isVip = false}) async {
    if (isVip) {
      final response = await VipOtpService.instance.resendOtp(phoneNumber);
      return response.status && (response.data?.otpSent ?? false);
    }

    final response = await NormalOtpService.instance.resendOtp(phoneNumber);
    return response.status && (response.data?.otpSent ?? false);
  }

  Future<bool> verifyOtp(
    String phoneNumber,
    String otp, {
    bool isVip = false,
  }) async {
    if (isVip) {
      final response = await VipOtpService.instance.verifyOtp(
        phone: phoneNumber,
        otp: otp,
      );
      return response.status && (response.data?.verified ?? false);
    }

    final response = await NormalOtpService.instance.verifyOtp(
      phone: phoneNumber,
      otp: otp,
    );
    return response.status && (response.data?.verified ?? false);
  }

  Future<bool> submitRegistration(RegistrationModel registration) async {
    AppLogger.info(
      "Submitting registration for ${registration.name}",
      tag: "RegistrationService",
    );
    await Future.delayed(const Duration(seconds: 2));

    AppLogger.success(
      "Registration submitted for ${registration.name}",
      tag: "RegistrationService",
    );
    return true;
  }
}
