class VipOtpResponse<T> {
  const VipOtpResponse({
    required this.status,
    required this.message,
    this.data,
  });

  final bool status;
  final String message;
  final T? data;

  factory VipOtpResponse.fromJson(
    dynamic json,
    T Function(dynamic json) dataParser,
  ) {
    if (json is! Map) {
      return const VipOtpResponse(
        status: false,
        message: 'Invalid response',
      );
    }

    final data = json['data'];
    return VipOtpResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: data != null ? dataParser(data) : null,
    );
  }
}

class VipOtpSendData {
  const VipOtpSendData({
    required this.otpSent,
    required this.phone,
    this.otp,
    this.expiresInMinutes,
    this.expiresAt,
  });

  final bool otpSent;
  final String phone;
  final String? otp;
  final int? expiresInMinutes;
  final String? expiresAt;

  factory VipOtpSendData.fromJson(dynamic json) {
    if (json is! Map) {
      return const VipOtpSendData(otpSent: false, phone: '');
    }

    return VipOtpSendData(
      otpSent: json['otp_sent'] == true,
      phone: json['phone']?.toString() ?? '',
      otp: json['otp']?.toString(),
      expiresInMinutes: _int(json['expires_in_minutes']),
      expiresAt: json['expires_at']?.toString(),
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}

class VipOtpVerifyData {
  const VipOtpVerifyData({
    required this.verified,
    required this.userExists,
    required this.loginSuccess,
    required this.phoneVerified,
    required this.isLoginBlocked,
    required this.isExpired,
    required this.isInvalid,
    required this.attemptsExceeded,
    required this.remainingAttempts,
    required this.phone,
    this.retryAfterSeconds,
    this.token,
    this.user,
  });

  final bool verified;
  final bool userExists;
  final bool loginSuccess;
  final bool phoneVerified;
  final bool isLoginBlocked;
  final bool isExpired;
  final bool isInvalid;
  final bool attemptsExceeded;
  final int remainingAttempts;
  final int? retryAfterSeconds;
  final String phone;
  final String? token;
  final Map<String, dynamic>? user;

  /// Backward-compatible alias for older API payloads.
  bool get isBlocked => isLoginBlocked;

  factory VipOtpVerifyData.fromJson(dynamic json) {
    if (json is! Map) {
      return const VipOtpVerifyData(
        verified: false,
        userExists: false,
        loginSuccess: false,
        phoneVerified: false,
        isLoginBlocked: false,
        isExpired: false,
        isInvalid: false,
        attemptsExceeded: false,
        remainingAttempts: 0,
        phone: '',
      );
    }

    return VipOtpVerifyData(
      verified: json['verified'] == true,
      userExists: json['user_exists'] == true,
      loginSuccess: json['login_success'] == true,
      phoneVerified: json['phone_verified'] == true,
      isLoginBlocked:
          json['is_login_blocked'] == true || json['is_blocked'] == true,
      isExpired: json['is_expired'] == true,
      isInvalid: json['is_invalid'] == true,
      attemptsExceeded: json['attempts_exceeded'] == true,
      remainingAttempts: _int(json['remaining_attempts']),
      retryAfterSeconds: _nullableInt(json['retry_after_seconds']),
      phone: json['phone']?.toString() ?? '',
      token: json['token']?.toString(),
      user: json['user'] is Map
          ? Map<String, dynamic>.from(json['user'] as Map)
          : null,
    );
  }

  String feedbackMessage({String fallback = 'Verification failed'}) {
    if (isLoginBlocked && retryAfterSeconds != null && retryAfterSeconds! > 0) {
      return 'Too many failed attempts. Try again in ${retryAfterSeconds}s';
    }

    if (isExpired) return 'OTP expired. Please request a new OTP.';

    if (isInvalid && remainingAttempts > 0) {
      return 'Wrong OTP. $remainingAttempts attempts left';
    }

    if (attemptsExceeded) {
      return 'Maximum attempts reached. Please request a new OTP.';
    }

    return fallback;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }
}
