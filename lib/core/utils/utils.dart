import 'dart:ui';

Color hexToColor(String? hex) {
  final buffer = StringBuffer();

  hex = hex ?? "#000000";
  // Remove #
  hex = hex.replaceFirst('#', '');

  // If only RGB, add full opacity
  if (hex.length == 6) {
    buffer.write('ff');
  }

  buffer.write(hex);

  return Color(int.parse(buffer.toString(), radix: 16));
}
