import 'package:holynikkah/modules/template/models/template_style.dart';

/// Relative position/size of an element, expressed as `0.0..1.0` fractions of
/// the canvas (never pixels) so templates render identically on any device.
class TemplateRect {
  TemplateRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final double x;
  final double y;
  final double w;
  final double h;

  factory TemplateRect.fromJson(Map<String, dynamic> json) {
    return TemplateRect(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      w: (json['w'] as num?)?.toDouble() ?? 0,
      h: (json['h'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A single visual element drawn on the canvas. Some types bind to a field's
/// value (`boundField`, `boundRow`); `box` can hold nested [children].
class TemplateElement {
  TemplateElement({
    required this.id,
    required this.type,
    this.rect,
    this.style,
    this.field,
    this.label,
    this.text,
    this.aspectRatio,
    this.children = const [],
  });

  final String id;
  final String type;
  final TemplateRect? rect;
  final TemplateStyle? style;
  final String? field;
  final String? label;
  final String? text;

  /// Crop ratio (width ÷ height) for `imageSlot` elements, supplied by the API
  /// so each cell crops to the exact shape it occupies on the canvas.
  final double? aspectRatio;
  final List<TemplateElement> children;

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    final rawRect = json['rect'];
    final rawStyle = json['style'];
    final rawChildren = json['children'];

    return TemplateElement(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      rect: rawRect is Map
          ? TemplateRect.fromJson(Map<String, dynamic>.from(rawRect))
          : null,
      style: rawStyle is Map
          ? TemplateStyle.fromJson(Map<String, dynamic>.from(rawStyle))
          : null,
      field: json['field']?.toString(),
      label: json['label']?.toString(),
      text: json['text']?.toString(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      children: rawChildren is List
          ? rawChildren
              .whereType<Map>()
              .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
