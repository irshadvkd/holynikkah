import 'dart:convert';
import 'dart:io';

import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';

/// On-disk cache for template read endpoints.
///
/// For each cache key we persist two things:
///  * the decoded JSON body (so the app works offline / on `304 Not Modified`)
///  * the `ETag` returned by the server (sent back as `If-None-Match`)
///
/// Stored under the app documents directory so it survives across launches.
class TemplateCache {
  TemplateCache._();

  static final TemplateCache instance = TemplateCache._();

  static const String _folderName = 'templates_cache';
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_folderName');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  String _safeKey(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

  File _bodyFile(Directory dir, String key) =>
      File('${dir.path}/${_safeKey(key)}.json');

  File _etagFile(Directory dir, String key) =>
      File('${dir.path}/${_safeKey(key)}.etag');

  /// The last stored ETag for [key], or null if nothing is cached.
  Future<String?> readEtag(String key) async {
    try {
      final dir = await _ensureDir();
      final file = _etagFile(dir, key);
      if (!file.existsSync()) return null;
      final etag = (await file.readAsString()).trim();
      return etag.isEmpty ? null : etag;
    } catch (e) {
      AppLogger.warning('Failed to read ETag for $key: $e', tag: 'TemplateCache');
      return null;
    }
  }

  /// The last cached body for [key], decoded back into JSON (Map or List).
  Future<dynamic> readBody(String key) async {
    try {
      final dir = await _ensureDir();
      final file = _bodyFile(dir, key);
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (e) {
      AppLogger.warning('Failed to read cache for $key: $e', tag: 'TemplateCache');
      return null;
    }
  }

  /// Persist a fresh [body] (decoded JSON) and its [etag] for [key].
  Future<void> write(String key, {required dynamic body, String? etag}) async {
    try {
      final dir = await _ensureDir();
      await _bodyFile(dir, key).writeAsString(jsonEncode(body));
      final etagFile = _etagFile(dir, key);
      if (etag != null && etag.isNotEmpty) {
        await etagFile.writeAsString(etag);
      } else if (etagFile.existsSync()) {
        await etagFile.delete();
      }
    } catch (e) {
      AppLogger.warning('Failed to write cache for $key: $e', tag: 'TemplateCache');
    }
  }

  /// Remove all cached templates (e.g. on logout).
  Future<void> clear() async {
    try {
      final dir = await _ensureDir();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
      _dir = null;
    } catch (e) {
      AppLogger.warning('Failed to clear template cache: $e', tag: 'TemplateCache');
    }
  }
}
