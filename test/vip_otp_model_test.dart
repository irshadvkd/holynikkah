import 'package:flutter_test/flutter_test.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/models/vip_otp_model.dart';

void main() {
  group('VipOtpSendData', () {
    test('parses live send success response', () {
      final response = VipOtpResponse.fromJson(
        {
          'status': true,
          'message': 'OTP sent successfully.',
          'data': {
            'otp_sent': true,
            'phone': '9876543210',
            'otp': '2255',
            'expires_in_minutes': 5,
            'expires_at': '2026-06-13T21:11:52Z',
          },
        },
        VipOtpSendData.fromJson,
      );

      expect(response.status, isTrue);
      expect(response.message, 'OTP sent successfully.');
      expect(response.data?.otpSent, isTrue);
      expect(response.data?.phone, '9876543210');
      expect(response.data?.otp, '2255');
      expect(response.data?.expiresInMinutes, 5);
    });
  });

  group('VipOtpVerifyData', () {
    test('parses latest invalid OTP response', () {
      final response = VipOtpResponse.fromJson(
        {
          'status': false,
          'message': 'Invalid OTP. You have 2 attempts remaining.',
          'data': {
            'verified': false,
            'is_login_blocked': false,
            'retry_after_seconds': 0,
            'phone': '9876543210',
          },
        },
        VipOtpVerifyData.fromJson,
      );

      final data = response.data!;
      expect(response.status, isFalse);
      expect(response.message, 'Invalid OTP. You have 2 attempts remaining.');
      expect(data.verified, isFalse);
      expect(data.isLoginBlocked, isFalse);
      expect(data.retryAfterSeconds, 0);
      expect(
        data.feedbackMessage(
          fallback: 'Invalid OTP. You have 2 attempts remaining.',
        ),
        'Invalid OTP. You have 2 attempts remaining.',
      );
    });

    test('parses latest login blocked response', () {
      final response = VipOtpResponse.fromJson(
        {
          'status': false,
          'message':
              'Too many failed attempts. Please try again after 1 minute.',
          'data': {
            'verified': false,
            'is_login_blocked': true,
            'retry_after_seconds': 60,
            'phone': '9876543210',
          },
        },
        VipOtpVerifyData.fromJson,
      );

      final data = response.data!;
      expect(response.status, isFalse);
      expect(data.isLoginBlocked, isTrue);
      expect(data.isBlocked, isTrue);
      expect(data.retryAfterSeconds, 60);
      expect(
        data.feedbackMessage(
          fallback:
              'Too many failed attempts. Please try again after 1 minute.',
        ),
        'Too many failed attempts. Try again in 60s',
      );
    });

    test('supports legacy blocked and invalid flags', () {
      final data = VipOtpVerifyData.fromJson({
        'verified': false,
        'is_blocked': true,
        'is_invalid': true,
        'remaining_attempts': 1,
        'retry_after_seconds': 45,
        'phone': '9876543210',
      });

      expect(data.isLoginBlocked, isTrue);
      expect(data.isInvalid, isTrue);
      expect(data.remainingAttempts, 1);
      expect(data.feedbackMessage(), 'Too many failed attempts. Try again in 45s');
    });

    test('parses expired OTP response', () {
      final data = VipOtpVerifyData.fromJson({
        'verified': false,
        'is_expired': true,
        'remaining_attempts': 0,
        'phone': '9876543210',
      });

      expect(data.isExpired, isTrue);
      expect(
        data.feedbackMessage(),
        'OTP expired. Please request a new OTP.',
      );
    });

    test('parses existing user login success response', () {
      final response = VipOtpResponse.fromJson(
        {
          'status': true,
          'message': 'OTP verified and login successful.',
          'data': {
            'verified': true,
            'user_exists': true,
            'login_success': true,
            'phone_verified': false,
            'is_login_blocked': false,
            'phone': '9876543210',
            'token': 'sample-token',
            'user': {'id': 1, 'name': 'Test User'},
          },
        },
        VipOtpVerifyData.fromJson,
      );

      final data = response.data!;
      expect(response.status, isTrue);
      expect(data.verified, isTrue);
      expect(data.loginSuccess, isTrue);
      expect(data.userExists, isTrue);
      expect(data.token, 'sample-token');
      expect(data.user?['name'], 'Test User');
    });

    test('parses new user registration success response', () {
      final data = VipOtpVerifyData.fromJson({
        'verified': true,
        'user_exists': false,
        'login_success': false,
        'phone_verified': true,
        'is_login_blocked': false,
        'phone': '9876543210',
      });

      expect(data.verified, isTrue);
      expect(data.phoneVerified, isTrue);
      expect(data.loginSuccess, isFalse);
      expect(data.userExists, isFalse);
    });

    test('handles null verify data safely', () {
      final response = VipOtpResponse.fromJson(
        {
          'status': false,
          'message': 'Invalid or expired OTP.',
          'data': null,
        },
        VipOtpVerifyData.fromJson,
      );

      expect(response.status, isFalse);
      expect(response.data, isNull);
    });
  });

  group('VipCategoriesResponse', () {
    test('parses live VIP categories with API colors', () {
      final categories = VipCategoriesResponse.parseCategories({
        'data': [
          {
            'id': 8,
            'sort_order': 1,
            'title': 'Struggling Class',
            'status': 'active',
            'networth': 'Less than ₹10 Lakh',
            'button_bg_color': '#4a6fa5',
            'button_text_color': '#ffffff',
          },
          {
            'id': 1,
            'sort_order': 8,
            'title': 'Billionaire',
            'status': 'active',
            'networth': '₹800+ Crore',
            'button_bg_color': '#194f2f',
            'button_text_color': '#ffffff',
          },
        ],
      });

      expect(categories.length, 2);
      expect(categories.first.name, 'Struggling Class');
      expect(categories.first.catId, '8');
      expect(categories.first.bgColor, '#4a6fa5');
      expect(categories.first.textColor, '#ffffff');
      expect(categories.first.sortOrder, 1);
      expect(categories.last.name, 'Billionaire');
      expect(categories.last.sortOrder, 8);
    });

    test('filters inactive categories and sorts by sort_order', () {
      final categories = VipCategoriesResponse.parseCategories({
        'data': [
          {
            'id': 2,
            'sort_order': 3,
            'title': 'Middle Class',
            'status': 'inactive',
            'networth': 'x',
            'button_bg_color': '#000000',
            'button_text_color': '#ffffff',
          },
          {
            'id': 3,
            'sort_order': 1,
            'title': 'Struggling Class',
            'status': 'active',
            'networth': 'y',
            'button_bg_color': '#111111',
            'button_text_color': '#ffffff',
          },
        ],
      });

      expect(categories.length, 1);
      expect(categories.single.name, 'Struggling Class');
    });
  });
}
