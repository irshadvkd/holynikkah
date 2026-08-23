import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/constants.dart';

class LegalPage {
  final String slug;
  final String title;
  final String content;
  final String updatedAt;

  const LegalPage({
    required this.slug,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory LegalPage.fromJson(Map<String, dynamic> json) {
    return LegalPage(
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class LegalService {
  LegalService._();
  static final LegalService instance = LegalService._();

  Future<LegalPage?> getPrivacyPolicy() async {
    final response = await ApiClient.instance.get<LegalPage>(
      AppConstants.urls.privacyPolicy,
      parser: (json) {
        if (json is Map && json['data'] != null) {
          return LegalPage.fromJson(json['data']);
        }
        throw Exception('Invalid JSON structure');
      },
    );

    if (response.success) {
      return response.data;
    }
    return null;
  }

  Future<LegalPage?> getTermsAndConditions() async {
    final response = await ApiClient.instance.get<LegalPage>(
      AppConstants.urls.termsAndConditions,
      parser: (json) {
        if (json is Map && json['data'] != null) {
          return LegalPage.fromJson(json['data']);
        }
        throw Exception('Invalid JSON structure');
      },
    );

    if (response.success) {
      return response.data;
    }
    return null;
  }
}
