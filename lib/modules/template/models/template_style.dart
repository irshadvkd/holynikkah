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
      ltrb = rawLtrb.map((e) => (e as num).toDouble()).toList();
    }

    return TemplateStyle(
      backgroundColor: json['backgroundColor']?.toString(),
      color: json['color']?.toString(),
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeight: (json['fontWeight'] as num?)?.toInt(),
      fontFamily: json['fontFamily']?.toString(),
      align: json['align']?.toString(),
      borderRadius: (json['borderRadius'] as num?)?.toDouble(),
      padding: (json['padding'] as num?)?.toDouble(),
      paddingLTRB: ltrb,
      fit: json['fit']?.toString(),
      source: mediaUrlOrNull(
        (json['source'] ?? json['image'])?.toString(),
      ),
      opacity: (json['opacity'] as num?)?.toDouble(),
      lineHeight: (json['lineHeight'] as num?)?.toDouble(),
    );
  }
}
