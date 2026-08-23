import 'dart:ui';

import 'package:holynikkah/core/utils/constants.dart';

/// Resolves a backend media reference into a fully-qualified URL.
///
/// The backend returns host-less relative paths (e.g. `api/reels/5/video`);
/// this prepends [AppConstants.urls.imageBaseUrl] (which keeps a trailing
/// slash). Root-relative paths (`/api/...`) have their leading slash stripped
/// first. Absolute URLs are returned as-is, except legacy `localhost`/
/// `127.0.0.1` hosts which are rewritten to the configured base host.
/// `null`/empty input yields an empty string.
String mediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';

  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) {
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final base = Uri.parse(AppConstants.urls.base);
      return uri.replace(host: base.host, port: base.port).toString();
    }
    return path;
  }

  final relative = path.startsWith('/') ? path.substring(1) : path;
  return '${AppConstants.urls.imageBaseUrl}$relative';
}

/// Like [mediaUrl] but preserves `null` for missing references (instead of
/// returning an empty string), so optional fields keep their null-coalescing
/// fallback behaviour.
String? mediaUrlOrNull(String? path) {
  if (path == null || path.isEmpty) return null;
  return mediaUrl(path);
}

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
