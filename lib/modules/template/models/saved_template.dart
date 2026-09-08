import 'package:holynikkah/core/utils/utils.dart';
import 'package:holynikkah/modules/template/models/template_definition.dart';

/// Lightweight saved-template entry returned by
/// `GET /{tier}-users/templates/saved` for the "My Templates" grid.
class SavedTemplate {
  SavedTemplate({
    required this.id,
    required this.templateId,
    required this.name,
    this.isDefault = false,
    this.thumbnail,
    this.templateName,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String templateId;
  final String name;
  final bool isDefault;
  final String? thumbnail;

  /// Display name of the underlying published template (e.g. "Nikkah Proposal").
  final String? templateName;

  /// Tier the template belongs to: `vip` or `normal`.
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SavedTemplate copyWith({bool? isDefault}) {
    return SavedTemplate(
      id: id,
      templateId: templateId,
      name: name,
      isDefault: isDefault ?? this.isDefault,
      thumbnail: thumbnail,
      templateName: templateName,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory SavedTemplate.fromJson(Map<String, dynamic> json) {
    return SavedTemplate(
      id: (json['id'] ?? '').toString(),
      templateId: (json['templateId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
      thumbnail: mediaUrlOrNull(
        (json['previewImage'] ?? json['thumbnail'])?.toString(),
      ),
      templateName: json['templateName']?.toString(),
      type: json['type']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

/// Parsed response of `GET /{tier}-users/templates/saved`.
class SavedTemplateListResult {
  SavedTemplateListResult({required this.items, this.total = 0});

  final List<SavedTemplate> items;
  final int total;

  factory SavedTemplateListResult.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .whereType<Map>()
          .map((e) => SavedTemplate.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return SavedTemplateListResult(items: items, total: items.length);
    }

    final map = Map<String, dynamic>.from(json as Map);
    final data = map['data'];

    // `{ data: { items: [...], meta: {...} } }` — actual API envelope.
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      final raw = inner['items'] as List? ?? const [];
      final items = raw
          .whereType<Map>()
          .map((e) => SavedTemplate.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final meta = Map<String, dynamic>.from(inner['meta'] as Map? ?? const {});
      return SavedTemplateListResult(
        items: items,
        total: parseInt(meta['total']) ?? items.length,
      );
    }

    // `{ data: [...] }` or `{ items: [...] }`
    final raw = (data ?? map['items'] ?? const []) as List;
    final items = raw
        .whereType<Map>()
        .map((e) => SavedTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? const {});

    return SavedTemplateListResult(
      items: items,
      total: parseInt(meta['total']) ?? items.length,
    );
  }
}

/// Full saved template: the stored field values plus the template definition,
/// from `GET /{tier}-users/templates/saved/{id}` (and `/saved/default`).
class SavedTemplateDetail {
  SavedTemplateDetail({
    required this.id,
    required this.templateId,
    required this.name,
    this.isDefault = false,
    this.previewImage,
    required this.values,
    required this.slots,
    required this.definition,
  });

  final String id;
  final String templateId;
  final String name;
  final bool isDefault;

  /// The last rendered preview/thumbnail stored on the server (if any).
  final String? previewImage;
  final Map<String, String> values;

  /// Per-slot saved images (slotId → host-less relative path). Kept relative so
  /// unchanged cells can be re-sent verbatim on update; prepend the image base
  /// URL via `mediaUrl()` for display.
  final Map<String, String> slots;
  final TemplateDefinition definition;

  factory SavedTemplateDetail.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final root = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final rawValues = Map<String, dynamic>.from(
      root['values'] as Map? ?? const {},
    );
    final values = rawValues.map(
      (key, value) => MapEntry(key, (value ?? '').toString()),
    );

    final rawSlots = root['slots'];
    final slots = rawSlots is Map
        ? rawSlots.map(
            (key, value) => MapEntry(key.toString(), (value ?? '').toString()),
          )
        : <String, String>{};

    final defJson =
        root['template'] ?? root['definition'] ?? root['templateDefinition'];

    return SavedTemplateDetail(
      id: (root['id'] ?? '').toString(),
      templateId: (root['templateId'] ?? '').toString(),
      name: (root['name'] ?? '').toString(),
      isDefault: root['isDefault'] == true,
      previewImage: mediaUrlOrNull(
        (root['previewImage'] ?? root['thumbnail'])?.toString(),
      ),
      values: values,
      slots: slots,
      definition: TemplateDefinition.fromJson(
        Map<String, dynamic>.from(defJson as Map),
      ),
    );
  }
}
