import 'package:holynikkah/core/utils/utils.dart';
import 'package:holynikkah/modules/template/models/template_canvas.dart';
import 'package:holynikkah/modules/template/models/template_element.dart';
import 'package:holynikkah/modules/template/models/template_field.dart';

/// Full template definition returned by `GET /templates/{id}` — the JSON the
/// app's generic renderer uses to build the form (page 1) and the preview
/// canvas (page 2).
class TemplateDefinition {
  TemplateDefinition({
    required this.id,
    required this.name,
    required this.type,
    this.schemaVersion = 1,
    this.status,
    this.thumbnail,
    this.createdAt,
    this.updatedAt,
    required this.canvas,
    this.fields = const [],
    this.elements = const [],
  });

  final String id;
  final String name;
  final String type;
  final int schemaVersion;
  final String? status;
  final String? thumbnail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TemplateCanvas canvas;
  final List<TemplateField> fields;
  final List<TemplateElement> elements;

  bool get isVip => type.toLowerCase() == 'vip';

  /// True when the template expects the end-user to upload a photo.
  bool get hasImageSlot =>
      _hasImageSlot(elements);

  static bool _hasImageSlot(List<TemplateElement> elements) {
    for (final el in elements) {
      if (el.type == 'imageSlot') return true;
      if (el.children.isNotEmpty && _hasImageSlot(el.children)) return true;
    }
    return false;
  }

  factory TemplateDefinition.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final rawCanvas = map['canvas'];
    final rawFields = map['fields'];
    final rawElements = map['elements'];

    return TemplateDefinition(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'normal').toString(),
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      status: map['status']?.toString(),
      thumbnail: mediaUrlOrNull(
        (map['previewImage'] ?? map['thumbnail'])?.toString(),
      ),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
      canvas: rawCanvas is Map
          ? TemplateCanvas.fromJson(Map<String, dynamic>.from(rawCanvas))
          : TemplateCanvas(),
      fields: rawFields is List
          ? rawFields
              .whereType<Map>()
              .map((e) => TemplateField.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      elements: rawElements is List
          ? rawElements
              .whereType<Map>()
              .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
