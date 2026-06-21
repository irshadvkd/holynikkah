import 'dart:io';

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

  static Future<VideoPlayerController> createController(VideoModel video) async {
    final url = video.videoUrl;
    if (url == null || url.isEmpty) {
      throw Exception('No video URL for reel ${video.id ?? video.title}');
    }

    final file = await _getCachedFile(url, reelId: video.id);
    AppLogger.debug('Playing reel from cache: ${file.path}', tag: 'ReelVideoLoader');
    return VideoPlayerController.file(file);
  }

  static Future<File> _getCachedFile(String url, {int? reelId}) async {
    if (!_cacheDir.existsSync()) {
      _cacheDir.createSync(recursive: true);
    }

    final fileName = reelId != null ? 'reel_$reelId.mp4' : 'reel_${url.hashCode}.mp4';
    final file = File('${_cacheDir.path}/$fileName');

    if (file.existsSync() && file.lengthSync() > 0) {
      return file;
    }

    AppLogger.info('Downloading reel video: $url', tag: 'ReelVideoLoader');
    await ApiClient.instance.dio.download(url, file.path);
    return file;
  }
}
