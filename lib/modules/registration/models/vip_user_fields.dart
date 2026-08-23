/// Shared helpers for VIP user payloads from auth/register APIs.
class VipUserFields {
  VipUserFields._();

  static bool isCategorySelected(Map<String, dynamic>? user) {
    if (user == null) return false;

    final value = user['is_category_selected'];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static bool isTemplateSelected(Map<String, dynamic>? user) {
    if (user == null) return false;

    final value = user['is_template_selected'];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static int? selectedTemplateId(Map<String, dynamic>? user) {
    if (user == null) return null;

    final value = user['template_id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? mobVisibility(Map<String, dynamic>? user) {
    if (user == null) return null;

    final value = user['mob_visibility'];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}
