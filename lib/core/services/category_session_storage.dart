import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategorySessionStorage {
  static final CategorySessionStorage _instance =
      CategorySessionStorage._internal();
  factory CategorySessionStorage() => _instance;
  CategorySessionStorage._internal();

  static const _storage = FlutterSecureStorage();
  static const String _isVipCategorySelectedKey = 'is_vip_category_selected';
  static const String _isNormalCategorySelectedKey =
      'is_normal_category_selected';

  Future<bool> isVipCategorySelected() async {
    final value = await _storage.read(key: _isVipCategorySelectedKey);
    return value == 'true';
  }

  Future<bool> isNormalCategorySelected() async {
    final value = await _storage.read(key: _isNormalCategorySelectedKey);
    return value == 'true';
  }

  Future<void> setVipCategorySelected() {
    return _storage.write(key: _isVipCategorySelectedKey, value: "true");
  }

  Future<void> setNormalCategorySelected(bool isSelected) {
    return _storage.write(
      key: _isNormalCategorySelectedKey,
      value: isSelected.toString(),
    );
  }

  Future<void> clearVipCategorySelection() {
    return _storage.delete(key: _isVipCategorySelectedKey);
  }

  Future<void> clearNormalCategorySelection() {
    return _storage.delete(key: _isNormalCategorySelectedKey);
  }

  Future<void> clearAllCategorySelections() async {
    await _storage.delete(key: _isVipCategorySelectedKey);
    await _storage.delete(key: _isNormalCategorySelectedKey);
  }

  // Legacy method for backward compatibility
  Future<bool> isCategorySelected() async {
    return await isVipCategorySelected();
  }


}
