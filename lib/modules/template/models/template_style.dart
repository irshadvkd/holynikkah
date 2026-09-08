import 'package:holynikkah/core/utils/utils.dart';

/// Optional styling shared by canvas elements. All keys are nullable so the
/// renderer can fall back to sensible defaults and stay forward-compatible
/// (unknown keys are simply ignored).
class TemplateStyle {
  TemplateStyle({
    this.backgroundColor,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.align,
    this.borderRadius,
    this.padding,
    this.paddingLTRB,
    this.fit,
    this.source,
    this.opacity,
    this.lineHeight,
  });

  final String? backgroundColor;
  final String? color;
  final double? fontSize;
  final int? fontWeight;
  final String? fontFamily;
  final String? align;
  final double? borderRadius;
  final double? padding;
  final List<double>? paddingLTRB;
  final String? fit;
  final String? source;
  final double? opacity;
  final double? lineHeight;

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    List<double>? ltrb;
    final rawLtrb = json['paddingLTRB'];
    if (rawLtrb is List && rawLtrb.length == 4) {
      ltrb = rawLtrb.map((e) => parseDouble(e) ?? 0.0).toList();
    }

    return TemplateStyle(
      backgroundColor: json['backgroundColor']?.toString(),
      color: json['color']?.toString(),
      fontSize: parseDouble(json['fontSize']),
      fontWeight: _parseFontWeight(json['fontWeight']),
      fontFamily: json['fontFamily']?.toString(),
      align: json['align']?.toString(),
      borderRadius: parseDouble(json['borderRadius'] ?? json['cornerRadius']),
      padding: parseDouble(json['padding']),
      paddingLTRB: ltrb,
      fit: json['fit']?.toString(),
      source: mediaUrlOrNull(
        (json['source'] ?? json['image'])?.toString(),
      ),
      opacity: parseDouble(json['opacity']),
      lineHeight: parseDouble(json['lineHeight']),
    );
  }

  static int? _parseFontWeight(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final trimmed = raw.trim();
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      switch (trimmed.toLowerCase()) {
        case 'thin':
        case 'w100':
          return 100;
        case 'extralight':
        case 'w200':
          return 200;
        case 'light':
        case 'w300':
          return 300;
        case 'normal':
        case 'regular':
        case 'w400':
          return 400;
        case 'medium':
        case 'w500':
          return 500;
        case 'semibold':
        case 'w600':
          return 600;
        case 'bold':
        case 'w700':
          return 700;
        case 'extrabold':
        case 'w800':
          return 800;
        case 'black':
        case 'w900':
          return 900;
      }
    }
    return null;
  }
}
