import 'package:dio/dio.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/vip_registration_model.dart';

class NormalRegistrationService {
  NormalRegistrationService._();

  static final NormalRegistrationService instance = NormalRegistrationService._();

  Future<VipRegistrationResponse> register(VipRegistrationRequest request) async {
    AppLogger.info(
      'Submitting normal registration for ${request.phoneNumber}',
      tag: 'NormalRegistrationService',
    );

    final fields = <String, dynamic>{
      'phone': request.phoneNumber,
      'phone_number': request.phoneNumber,
      'name': request.fullName,
      'full_name': request.fullName,
      'gender': request.normalizedGender,
      'state_id': request.stateId,
      'district_id': request.districtId,
      'city': request.city,
      'info': request.information,
      'information': request.information,
      'mob_visibility': request.mobVisibility ? 'true' : 'false',
      if (request.email != null && request.email!.isNotEmpty)
        'email': request.email,
    };

    if (request.profilePicPath != null && request.profilePicPath!.isNotEmpty) {
      fields['profile_pic'] = await MultipartFile.fromFile(
        request.profilePicPath!,
        filename: _fileName(request.profilePicPath!),
      );
    }

    final formData = FormData.fromMap(fields);

    final response = await ApiClient.instance.upload<dynamic>(
      AppConstants.urls.normalUsersRegister,
      formData: formData,
      parser: (json) => json,
    );

    final rawBody = response.success ? response.data : response.error?.data;
    final parsed = VipRegistrationResponse.fromJson(rawBody);

    if (parsed.status) {
      AppLogger.success(
        'Normal registration completed for ${request.phoneNumber}',
        tag: 'NormalRegistrationService',
      );
      return parsed;
    }

    final message = parsed.message.isNotEmpty
        ? parsed.message
        : response.message ?? 'Registration failed';

    AppLogger.warning(
      'Normal registration failed for ${request.phoneNumber}: $message',
      tag: 'NormalRegistrationService',
    );

    return VipRegistrationResponse(
      status: false,
      message: message,
      data: parsed.data,
    );
  }

  String _fileName(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : 'profile_pic.jpg';
  }
}
