import 'package:holynikkah/modules/registration/models/phone_visibility.dart';
import 'package:holynikkah/modules/registration/models/vip_user_fields.dart';

class RegistrationUser {
  const RegistrationUser({
    required this.raw,
    this.mobVisibility,
    this.isCategorySelected = false,
  });

  final Map<String, dynamic> raw;
  final bool? mobVisibility;
  final bool isCategorySelected;

  PhoneVisibility get phoneVisibility =>
      PhoneVisibility.fromMobVisibility(mobVisibility);

  factory RegistrationUser.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const RegistrationUser(raw: {});
    }

    return RegistrationUser(
      raw: Map<String, dynamic>.from(json),
      mobVisibility: VipUserFields.mobVisibility(json),
      isCategorySelected: VipUserFields.isCategorySelected(json),
    );
  }
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.phoneNumber,
    required this.fullName,
    required this.gender,
    required this.stateId,
    required this.districtId,
    required this.city,
    required this.information,
    required this.mobVisibility,
    this.profilePicPath,
  });

  final String phoneNumber;
  final String fullName;
  final String gender;
  final int stateId;
  final int districtId;
  final String city;
  final String information;
  final bool mobVisibility;
  final String? profilePicPath;

  /// API expects lowercase gender, e.g. `male` / `female`.
  String get normalizedGender => gender.trim().toLowerCase();
}

class RegistrationResponse {
  const RegistrationResponse({
    required this.status,
    required this.message,
    this.data,
    this.token,
    this.user,
    this.registrationUser,
  });

  final bool status;
  final String message;
  final Map<String, dynamic>? data;
  final String? token;
  final Map<String, dynamic>? user;
  final RegistrationUser? registrationUser;

  factory RegistrationResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return const RegistrationResponse(
        status: false,
        message: 'Invalid response',
      );
    }

    final data = json['data'];
    final parsedData = data is Map ? Map<String, dynamic>.from(data) : null;
    final token =
        json['token']?.toString() ?? parsedData?['token']?.toString();
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : parsedData?['user'] is Map
            ? Map<String, dynamic>.from(parsedData!['user'] as Map)
            : null;

    return RegistrationResponse(
      status: json['status'] == true || json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: parsedData,
      token: token,
      user: userMap,
      registrationUser: RegistrationUser.fromJson(userMap),
    );
  }
}

/// Backward-compatible aliases used by VIP/normal registration services.
typedef VipRegistrationRequest = RegistrationRequest;
typedef VipRegistrationResponse = RegistrationResponse;
