import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/vip_otp_model.dart';

class VipOtpService {
  VipOtpService._();

  static final VipOtpService instance = VipOtpService._();

  Future<VipOtpResponse<VipOtpSendData>> sendOtp(String phone) async {
    AppLogger.info('Sending VIP OTP to $phone', tag: 'VipOtpService');
    return _postOtp<VipOtpSendData>(
      path: AppConstants.urls.vipOtpSend,
      body: {'phone': phone},
      dataParser: VipOtpSendData.fromJson,
      action: 'Send',
      phone: phone,
    );
  }

  Future<VipOtpResponse<VipOtpSendData>> resendOtp(String phone) async {
    AppLogger.info('Resending VIP OTP to $phone', tag: 'VipOtpService');
    return _postOtp<VipOtpSendData>(
      path: AppConstants.urls.vipOtpResend,
      body: {'phone': phone},
      dataParser: VipOtpSendData.fromJson,
      action: 'Resend',
      phone: phone,
    );
  }

  Future<VipOtpResponse<VipOtpVerifyData>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    AppLogger.info('Verifying VIP OTP for $phone', tag: 'VipOtpService');

    final response = await ApiClient.instance.post<dynamic>(
      AppConstants.urls.vipOtpVerify,
      data: {
        'phone': phone,
        'otp': otp,
      },
      parser: (json) => json,
    );

    final rawBody = response.success ? response.data : response.error?.data;
    final parsed = VipOtpResponse.fromJson(
      rawBody,
      VipOtpVerifyData.fromJson,
    );

    if (parsed.status && parsed.data?.verified == true) {
      AppLogger.success('VIP OTP verified for $phone', tag: 'VipOtpService');
    } else {
      AppLogger.warning(
        'VIP OTP verification failed for $phone: ${parsed.message}',
        tag: 'VipOtpService',
      );
    }

    return parsed;
  }

  Future<VipOtpResponse<T>> _postOtp<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(dynamic json) dataParser,
    required String action,
    required String phone,
  }) async {
    final response = await ApiClient.instance.post<dynamic>(
      path,
      data: body,
      parser: (json) => json,
    );

    final rawBody = response.success ? response.data : response.error?.data;
    final parsed = VipOtpResponse.fromJson(rawBody, dataParser);

    if (parsed.status) {
      AppLogger.success(
        'VIP OTP $action succeeded for $phone',
        tag: 'VipOtpService',
      );
    } else {
      AppLogger.warning(
        'VIP OTP $action failed for $phone: ${parsed.message}',
        tag: 'VipOtpService',
      );
    }

    return parsed;
  }
}
