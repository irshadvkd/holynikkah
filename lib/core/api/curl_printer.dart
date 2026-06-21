import 'dart:convert';

import 'package:dio/dio.dart';

/// Builds a copy-pasteable cURL command from a Dio [RequestOptions].
class CurlPrinter {
  CurlPrinter._();

  static String fromRequest(RequestOptions options, {bool maskSecrets = true}) {
    final buffer = StringBuffer();
    final method = options.method.toUpperCase();
    final uri = options.uri.toString();

    buffer.write("curl -X $method '${_escape(uri)}'");

    final headers = Map<String, dynamic>.from(options.headers);
    headers.forEach((key, value) {
      if (value == null) return;
      final headerValue = maskSecrets && _isSensitiveHeader(key)
          ? _mask(value.toString())
          : value.toString();
      buffer.write(" \\\n  -H '${_escape('$key: $headerValue')}'");
    });

    final body = _resolveBody(options);
    if (body != null && body.isNotEmpty) {
      buffer.write(" \\\n  -d '${_escape(body)}'");
    }

    return buffer.toString();
  }

  static String? _resolveBody(RequestOptions options) {
    final data = options.data;
    if (data == null) return null;

    if (data is String) return data;

    if (data is Map || data is List) {
      return jsonEncode(data);
    }

    if (data is FormData) {
      final fields = data.fields
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      final files = data.files
          .map((e) => '${e.key}=<file:${e.value.filename ?? 'binary'}>')
          .join('&');
      return [fields, files].where((e) => e.isNotEmpty).join('&');
    }

    return data.toString();
  }

  static bool _isSensitiveHeader(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'authorization' ||
        normalized == 'cookie' ||
        normalized.contains('token') ||
        normalized.contains('api-key') ||
        normalized.contains('apikey');
  }

  static String _mask(String value) {
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}***${value.substring(value.length - 3)}';
  }

  static String _escape(String value) => value.replaceAll("'", r"'\''");
}
