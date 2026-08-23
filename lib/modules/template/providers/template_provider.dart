import 'dart:io';

import 'package:flutter/material.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/services/template_session_storage.dart';
import 'package:holynikkah/modules/registration/models/vip_user_fields.dart';
import 'package:holynikkah/modules/template/models/saved_template.dart';
import 'package:holynikkah/modules/template/models/template_definition.dart';
import 'package:holynikkah/modules/template/models/template_summary.dart';
import 'package:holynikkah/modules/template/services/template_service.dart';

enum TemplateLoadStatus { idle, loading, success, error }

/// Drives the template picker (list) and template opening (detail) flows
/// against [TemplateService]. The service handles ETag caching + offline.
class TemplateProvider extends ChangeNotifier {
  final TemplateService _service = TemplateService.instance;

  // ─── List state ─────────────────────────────────────────────────────────
  /// Cached lists per tier so toggling VIP/Normal is instant.
  final Map<String, List<TemplateSummary>> _listsByType = {};

  TemplateLoadStatus _listStatus = TemplateLoadStatus.idle;
  String? _listError;
  String _currentType = 'vip';

  TemplateLoadStatus get listStatus => _listStatus;
  String? get listError => _listError;
  String get currentType => _currentType;

  List<TemplateSummary> get templates =>
      _listsByType[_currentType] ?? const [];

  bool get isVipSelected => _currentType == 'vip';

  // ─── Detail state ───────────────────────────────────────────────────────
  TemplateLoadStatus _detailStatus = TemplateLoadStatus.idle;
  String? _detailError;

  TemplateLoadStatus get detailStatus => _detailStatus;
  String? get detailError => _detailError;

  // ─── Saved (user-filled) templates ───────────────────────────────────────
  List<SavedTemplate> _savedTemplates = const [];
  TemplateLoadStatus _savedStatus = TemplateLoadStatus.idle;
  String? _savedError;

  List<SavedTemplate> get savedTemplates => _savedTemplates;
  TemplateLoadStatus get savedStatus => _savedStatus;
  String? get savedError => _savedError;

  // ─── Template selection flag (session-backed, per tier) ───────────────────
  bool _isVipTemplateSelected = false;
  bool _isNormalTemplateSelected = false;
  bool _selectionLoaded = false;

  bool get isVipTemplateSelected => _isVipTemplateSelected;
  bool get isNormalTemplateSelected => _isNormalTemplateSelected;
  bool get selectionLoaded => _selectionLoaded;

  bool isTemplateSelectedFor({required bool isVip}) =>
      isVip ? _isVipTemplateSelected : _isNormalTemplateSelected;

  /// Load both tiers' template-selection flags from secure storage.
  Future<void> loadTemplateSelection() async {
    _isVipTemplateSelected =
        await TemplateSessionStorage().isVipTemplateSelected();
    _isNormalTemplateSelected =
        await TemplateSessionStorage().isNormalTemplateSelected();
    _selectionLoaded = true;
    notifyListeners();
  }

  /// Sync VIP flag from an API user payload (`is_template_selected`).
  Future<void> applyVipTemplateFromUser(Map<String, dynamic>? user) async {
    _isVipTemplateSelected = VipUserFields.isTemplateSelected(user);
    await TemplateSessionStorage()
        .setVipTemplateSelected(_isVipTemplateSelected);
    notifyListeners();
  }

  /// Sync normal flag from an API user payload (`is_template_selected`).
  Future<void> applyNormalTemplateFromUser(Map<String, dynamic>? user) async {
    _isNormalTemplateSelected = VipUserFields.isTemplateSelected(user);
    await TemplateSessionStorage()
        .setNormalTemplateSelected(_isNormalTemplateSelected);
    notifyListeners();
  }

  /// Mark the tier's template as selected (session + in-memory) so any gate
  /// watching this flag advances. Used after a default is set.
  Future<void> markTemplateSelected({required bool isVip}) async {
    if (isVip) {
      _isVipTemplateSelected = true;
      await TemplateSessionStorage().setVipTemplateSelected(true);
    } else {
      _isNormalTemplateSelected = true;
      await TemplateSessionStorage().setNormalTemplateSelected(true);
    }
    notifyListeners();
  }

  /// `POST /{tier}-users/template/select` — persist the chosen template id on
  /// the server and update the session flag. Returns `true` on success.
  Future<bool> selectTemplate({
    required bool isVip,
    required String templateId,
  }) async {
    final response = await _service.selectTemplate(
      isVip: isVip,
      templateId: templateId,
    );

    final ok = response.success && (response.data ?? false);
    if (ok) {
      if (isVip) {
        _isVipTemplateSelected = true;
        await TemplateSessionStorage().setVipTemplateSelected(true);
      } else {
        _isNormalTemplateSelected = true;
        await TemplateSessionStorage().setNormalTemplateSelected(true);
      }
      notifyListeners();
    }
    return ok;
  }

  /// Switch the active tier and (re)load its published templates.
  Future<void> selectType(String type, {bool forceReload = false}) async {
    _currentType = type;
    notifyListeners();
    await loadTemplates(forceReload: forceReload);
  }

  /// `GET /templates?type={tier}&status=published`
  Future<void> loadTemplates({bool forceReload = false}) async {
    if (!forceReload && (_listsByType[_currentType]?.isNotEmpty ?? false)) {
      _listStatus = TemplateLoadStatus.success;
      notifyListeners();
      return;
    }

    _listStatus = TemplateLoadStatus.loading;
    _listError = null;
    notifyListeners();

    final response = await _service.fetchTemplates(
      type: _currentType,
      status: 'published',
    );

    if (response.success && response.data != null) {
      _listsByType[_currentType] = response.data!.templates;
      _listStatus = TemplateLoadStatus.success;
    } else {
      _listError = response.message ?? 'Failed to load templates';
      _listStatus = TemplateLoadStatus.error;
    }
    notifyListeners();
  }

  /// `GET /templates/{id}` — returns the full definition (or null on failure).
  Future<TemplateDefinition?> loadTemplate(String id) async {
    _detailStatus = TemplateLoadStatus.loading;
    _detailError = null;
    notifyListeners();

    final response = await _service.fetchTemplate(id);

    if (response.success && response.data != null) {
      _detailStatus = TemplateLoadStatus.success;
      notifyListeners();
      return response.data;
    }

    _detailError = response.message ?? 'Failed to load template';
    _detailStatus = TemplateLoadStatus.error;
    notifyListeners();
    return null;
  }

  // ─── Saved templates ──────────────────────────────────────────────────────

  /// `GET /{tier}-users/templates/saved` — the signed-in user's saved templates.
  Future<void> loadSavedTemplates({required bool isVip}) async {
    _savedStatus = TemplateLoadStatus.loading;
    _savedError = null;
    notifyListeners();

    final response = await _service.fetchSavedTemplates(isVip: isVip);

    if (response.success && response.data != null) {
      _savedTemplates = response.data!.items;
      _savedStatus = TemplateLoadStatus.success;
    } else {
      _savedError = response.message ?? 'Failed to load saved templates';
      _savedStatus = TemplateLoadStatus.error;
    }
    notifyListeners();
  }

  /// `GET /{tier}-users/templates/saved/{id}` — prefilled values + definition.
  Future<SavedTemplateDetail?> openSavedTemplate({
    required bool isVip,
    required String id,
  }) async {
    final response = await _service.fetchSavedTemplate(isVip: isVip, id: id);
    if (response.success && response.data != null) return response.data;
    _detailError = response.message ?? 'Failed to open saved template';
    return null;
  }

  /// Create a saved template. Returns `null` on success, else an error message.
  Future<String?> createSavedTemplate({
    required bool isVip,
    required String templateId,
    required String name,
    required Map<String, String> values,
    File? previewImage,
    Map<String, File>? slotImages,
    Map<String, String>? slots,
    bool? isDefault,
  }) async {
    final response = await _service.createSavedTemplate(
      isVip: isVip,
      templateId: templateId,
      name: name,
      values: values,
      previewImage: previewImage,
      slotImages: slotImages,
      slots: slots,
      isDefault: isDefault,
    );
    return response.success ? null : _humanizeError(response);
  }

  /// Update a saved template. Returns `null` on success, else an error message.
  Future<String?> updateSavedTemplate({
    required bool isVip,
    required String id,
    String? name,
    Map<String, String>? values,
    File? previewImage,
    Map<String, File>? slotImages,
    Map<String, String>? slots,
    bool? isDefault,
  }) async {
    final response = await _service.updateSavedTemplate(
      isVip: isVip,
      id: id,
      name: name,
      values: values,
      previewImage: previewImage,
      slotImages: slotImages,
      slots: slots,
      isDefault: isDefault,
    );
    return response.success ? null : _humanizeError(response);
  }

  /// `PATCH /saved/{id}/default`. Returns `true` on success.
  Future<bool> makeSavedTemplateDefault({
    required bool isVip,
    required String id,
  }) async {
    final response =
        await _service.makeSavedTemplateDefault(isVip: isVip, id: id);
    if (response.success) {
      _savedTemplates = _savedTemplates
          .map((t) => t.copyWith(isDefault: t.id == id))
          .toList();
      notifyListeners();
    }
    return response.success;
  }

  /// `DELETE /saved/{id}`. Returns `true` on success.
  Future<bool> deleteSavedTemplate({
    required bool isVip,
    required String id,
  }) async {
    final response = await _service.deleteSavedTemplate(isVip: isVip, id: id);
    if (response.success) {
      _savedTemplates =
          _savedTemplates.where((t) => t.id != id).toList(growable: false);
      notifyListeners();
    }
    return response.success;
  }

  /// Builds a readable message from a failed save, surfacing 422 per-field
  /// validation errors when the server returns them.
  String _humanizeError(ApiResponse response) {
    final data = response.error?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.entries.map((e) {
          final value = e.value;
          final first = value is List && value.isNotEmpty
              ? value.first.toString()
              : value.toString();
          return '${e.key}: $first';
        }).join('\n');
      }
    }
    return response.message ?? 'Something went wrong';
  }
}
