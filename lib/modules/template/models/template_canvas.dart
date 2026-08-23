import 'package:holynikkah/core/utils/utils.dart';

/// The canvas background — either a remote image or a solid color.
class TemplateBackground {
  TemplateBackground({
    required this.type,
    this.source,
    this.color,
    this.fit,
  });

  final String type;

  /// Resolved image URL. The API may send this as `image` (current) or `source`
  /// (legacy spec); both are accepted.
  final String? source;
  final String? color;
  final String? fit;

  bool get isImage => type.toLowerCase() == 'image';

  factory TemplateBackground.fromJson(Map<String, dynamic> json) {
    return TemplateBackground(
      type: (json['type'] ?? 'color').toString(),
      source: mediaUrlOrNull(
        (json['image'] ?? json['source'])?.toString(),
      ),
      color: json['color']?.toString(),
      fit: json['fit']?.toString(),
    );
  }
}

/// The fixed-aspect drawing surface that becomes the exported PNG.
class TemplateCanvas {
  TemplateCanvas({
    this.aspectRatio = 0.75,
    this.background,
  });

  final double aspectRatio;
  final TemplateBackground? background;

  factory TemplateCanvas.fromJson(Map<String, dynamic> json) {
    final rawBg = json['background'];
    return TemplateCanvas(
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 0.75,
      background: rawBg is Map
          ? TemplateBackground.fromJson(Map<String, dynamic>.from(rawBg))
          : null,
    );
  }
}
