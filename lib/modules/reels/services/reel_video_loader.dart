import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/video_model.dart';
import 'package:video_player/video_player.dart';

/// Loads reel videos for playback.
///
/// iOS AVPlayer requires HTTP byte-range (206) support for streaming.
/// The Laravel dev server returns 200 for range requests, so we download
/// the full file first and play from local cache.
class ReelVideoLoader {
  ReelVideoLoader._();

  static final Directory _cacheDir =
      Directory('${Directory.systemTemp.path}/reels_cache');

  static String _generateCacheKey(String url) {
    return md5.convert(utf8.encode(url.trim())).toString();
  }

  static Future<VideoPlayerController> createController(
    VideoModel video, {
    bool forceRefresh = false,
  }) async {
    final url = video.videoUrl;
    if (url == null || url.isEmpty) {
      throw Exception('No video URL for reel ${video.id ?? video.title}');
    }

    final file = await getCachedFile(url, forceRefresh: forceRefresh);
    AppLogger.debug('Playing reel from cache: ${file.path}', tag: 'ReelVideoLoader');
    return VideoPlayerController.file(file);
  }

  static Future<File> getCachedFile(
    String url, {
    String? id,
    bool forceRefresh = false,
  }) async {
    if (!_cacheDir.existsSync()) {
      _cacheDir.createSync(recursive: true);
    }

    final hashKey = _generateCacheKey(url);
    final fileName = 'video_$hashKey.mp4';
    final file = File('${_cacheDir.path}/$fileName');

    if (!forceRefresh && file.existsSync() && file.lengthSync() > 0) {
      return file;
    }

    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        AppLogger.warning('Failed to remove stale video file: $e', tag: 'ReelVideoLoader');
      }
    }

    AppLogger.info('Downloading video for playback: $url', tag: 'ReelVideoLoader');
    await ApiClient.instance.dio.download(url, file.path);
    return file;
  }

  /// Clears all cached reel video files from local storage.
  static Future<void> clearCache() async {
    try {
      if (_cacheDir.existsSync()) {
        final entities = _cacheDir.listSync(recursive: false);
        for (final entity in entities) {
          if (entity is File) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
        AppLogger.info(
          'Cleared ${entities.length} cached reel videos from disk',
          tag: 'ReelVideoLoader',
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to clear reels cache: $e',
        tag: 'ReelVideoLoader',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
