import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists whether the VIP / Normal user has selected a template, mirroring
/// [CategorySessionStorage]. Kept separate per tier so the two flows are
/// independent.
class TemplateSessionStorage {
  static final TemplateSessionStorage _instance =
      TemplateSessionStorage._internal();
  factory TemplateSessionStorage() => _instance;
  TemplateSessionStorage._internal();

  static const _storage = FlutterSecureStorage();
  static const String _isVipTemplateSelectedKey = 'is_vip_template_selected';
  static const String _isNormalTemplateSelectedKey =
      'is_normal_template_selected';

  Future<bool> isVipTemplateSelected() async {
    final value = await _storage.read(key: _isVipTemplateSelectedKey);
    return value == 'true';
  }

  Future<bool> isNormalTemplateSelected() async {
    final value = await _storage.read(key: _isNormalTemplateSelectedKey);
    return value == 'true';
  }

  Future<void> setVipTemplateSelected(bool isSelected) {
    return _storage.write(
      key: _isVipTemplateSelectedKey,
      value: isSelected.toString(),
    );
  }

  Future<void> setNormalTemplateSelected(bool isSelected) {
    return _storage.write(
      key: _isNormalTemplateSelectedKey,
      value: isSelected.toString(),
    );
  }

  Future<void> clearVipTemplateSelection() {
    return _storage.delete(key: _isVipTemplateSelectedKey);
  }

  Future<void> clearNormalTemplateSelection() {
    return _storage.delete(key: _isNormalTemplateSelectedKey);
  }

  Future<void> clearAllTemplateSelections() async {
    await _storage.delete(key: _isVipTemplateSelectedKey);
    await _storage.delete(key: _isNormalTemplateSelectedKey);
  }
}
