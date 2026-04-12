import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategorySessionStorage {
  static final CategorySessionStorage _instance = CategorySessionStorage._internal();
  factory CategorySessionStorage() => _instance;
  CategorySessionStorage._internal();

  static const _storage = FlutterSecureStorage();
  static const String _isCategorySelectedKey = 'is_category_selected';

  Future<bool> isCategorySelected() async {
    final value = await _storage.read(key: _isCategorySelectedKey);
    return value == 'true';
  }

  Future<void> setCategorySelected(bool isSelected) {
    return _storage.write(key: _isCategorySelectedKey, value: isSelected.toString());
  }

  Future<void> clearCategorySelection() {
    return _storage.delete(key: _isCategorySelectedKey);
  }
}