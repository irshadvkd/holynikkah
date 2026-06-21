import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/vip_otp_model.dart';

class NormalOtpService {
  NormalOtpService._();

  static final NormalOtpService instance = NormalOtpService._();

  Future<VipOtpResponse<VipOtpSendData>> sendOtp(String phone) async {
    AppLogger.info('Sending normal OTP to $phone', tag: 'NormalOtpService');
    return _postOtp<VipOtpSendData>(
      path: AppConstants.urls.normalOtpSend,
      body: {'phone': phone},
      dataParser: VipOtpSendData.fromJson,
      action: 'Send',
      phone: phone,
    );
  }

  Future<VipOtpResponse<VipOtpSendData>> resendOtp(String phone) async {
    return sendOtp(phone);
  }

  Future<VipOtpResponse<VipOtpVerifyData>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    AppLogger.info('Verifying normal OTP for $phone', tag: 'NormalOtpService');

    final response = await ApiClient.instance.post<dynamic>(
      AppConstants.urls.normalOtpVerify,
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
      AppLogger.success('Normal OTP verified for $phone', tag: 'NormalOtpService');
    } else {
      AppLogger.warning(
        'Normal OTP verification failed for $phone: ${parsed.message}',
        tag: 'NormalOtpService',
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
        'Normal OTP $action succeeded for $phone',
        tag: 'NormalOtpService',
      );
    } else {
      AppLogger.warning(
        'Normal OTP $action failed for $phone: ${parsed.message}',
        tag: 'NormalOtpService',
      );
    }

    return parsed;
  }
}
