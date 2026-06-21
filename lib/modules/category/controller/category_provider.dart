/// 🔥 category_provider.dart

import 'package:flutter/material.dart';
import 'package:holynikkah/core/services/category_session_storage.dart';
import 'package:holynikkah/modules/registration/models/vip_user_fields.dart';

class CategoryProvider extends ChangeNotifier {
  bool _isVipSelected = false;
  bool _isNormalSelected = false;
  bool _isLoaded = false;

  bool get isVipSelected => _isVipSelected;
  bool get isNormalSelected => _isNormalSelected;
  bool get isLoaded => _isLoaded;

  /// 🔥 Load both selections from storage
  Future<void> loadCategory() async {
    _isVipSelected = await CategorySessionStorage().isVipCategorySelected();
    _isNormalSelected = await CategorySessionStorage()
        .isNormalCategorySelected();
    _isLoaded = true;
    notifyListeners();
  }

  /// 🔥 Update VIP selection
  Future<void> setVipSelected(bool value) async {
    _isVipSelected = value;
    await CategorySessionStorage().setVipCategorySelected(value);
    notifyListeners();
  }

  /// Sync VIP category flag from API user payload (`is_category_selected`).
  Future<void> applyVipCategoryFromUser(Map<String, dynamic>? user) async {
    await setVipSelected(VipUserFields.isCategorySelected(user));
  }

  /// Sync normal category flag from API user payload (`is_category_selected`).
  Future<void> applyNormalCategoryFromUser(Map<String, dynamic>? user) async {
    await setNormalSelected(VipUserFields.isCategorySelected(user));
  }

  /// 🔥 Update Normal selection
  Future<void> setNormalSelected(bool value) async {
    _isNormalSelected = value;
    await CategorySessionStorage().setNormalCategorySelected(value);
    notifyListeners();
  }

  /// 🔥 Clear all selections
  Future<void> clearSelections() async {
    _isVipSelected = false;
    _isNormalSelected = false;
    await CategorySessionStorage().clearVipCategorySelection();
    await CategorySessionStorage().setNormalCategorySelected(false);
    notifyListeners();
  }

  /// 🔥 Check if any category is selected
  bool get hasSelection => _isVipSelected || _isNormalSelected;
}
