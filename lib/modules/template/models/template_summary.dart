import 'package:holynikkah/core/utils/utils.dart';

/// Lightweight template entry returned by `GET /templates` for the picker grid.
class TemplateSummary {
  TemplateSummary({
    required this.id,
    required this.name,
    required this.type,
    this.status,
    this.thumbnail,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String? status;
  final String? thumbnail;
  final DateTime? updatedAt;

  bool get isVip => type.toLowerCase() == 'vip';

  factory TemplateSummary.fromJson(Map<String, dynamic> json) {
    return TemplateSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'normal').toString(),
      status: json['status']?.toString(),
      thumbnail: mediaUrlOrNull(
        (json['previewImage'] ?? json['thumbnail'])?.toString(),
      ),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

/// Parsed response of `GET /templates` — `{ "data": [...], "meta": {...} }`.
class TemplateListResult {
  TemplateListResult({
    required this.templates,
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
  });

  final List<TemplateSummary> templates;
  final int total;
  final int page;
  final int pageSize;

  factory TemplateListResult.fromJson(dynamic json) {
    // Tolerate either the documented `{data, meta}` envelope or a bare list.
    if (json is List) {
      return TemplateListResult(
        templates: json
            .whereType<Map>()
            .map((e) => TemplateSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        total: json.length,
      );
    }

    final map = Map<String, dynamic>.from(json as Map);
    final data = (map['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => TemplateSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? const {});

    return TemplateListResult(
      templates: data,
      total: parseInt(meta['total']) ?? data.length,
      page: parseInt(meta['page']) ?? 1,
      pageSize: parseInt(meta['pageSize']) ?? 20,
    );
  }
}
