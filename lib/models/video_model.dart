import 'package:holynikkah/core/utils/utils.dart';

class VideoModel {
  final int? id;
  final String title;
  final String description;
  final String subtitle;
  final String thumb;
  final List<String> sources;
  final bool isWatched;

  VideoModel({
    this.id,
    required this.title,
    required this.description,
    required this.subtitle,
    required this.thumb,
    required this.sources,
    this.isWatched = false,
  });

  String? get videoUrl => sources.isNotEmpty ? sources.first : null;

  VideoModel copyWith({
    int? id,
    String? title,
    String? description,
    String? subtitle,
    String? thumb,
    List<String>? sources,
    bool? isWatched,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subtitle: subtitle ?? this.subtitle,
      thumb: thumb ?? this.thumb,
      sources: sources ?? this.sources,
      isWatched: isWatched ?? this.isWatched,
    );
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      title: _string(json['title'] ?? json['name']),
      description: _string(json['description']),
      subtitle: _string(json['subtitle']),
      thumb: _parseThumb(json),
      sources: _parseSources(json),
      isWatched: _bool(json['is_watched'] ?? json['watched']),
    );
  }

  static String _string(dynamic value) => value?.toString() ?? '';

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static String _parseThumb(Map<String, dynamic> json) {
    return mediaUrl(
      _string(
        json['thumb'] ??
            json['thumbnail'] ??
            json['thumbnail_url'] ??
            json['image'] ??
            json['poster'],
      ),
    );
  }

  static List<String> _parseSources(Map<String, dynamic> json) {
    final sources = json['sources'];
    if (sources is List) {
      return _normalizeUrls(
        sources.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
      );
    }

    final single = json['video_url'] ??
        json['video'] ??
        json['url'] ??
        json['source'] ??
        json['file'];
    if (single != null && single.toString().isNotEmpty) {
      return _normalizeUrls([single.toString()]);
    }

    return [];
  }

  /// Resolves host-less relative API paths to fully-qualified media URLs.
  static List<String> _normalizeUrls(List<String> urls) {
    return urls.map(mediaUrl).where((url) => url.isNotEmpty).toList();
  }
}

class CategoryModel {
  final String name;
  final List<VideoModel> videos;

  CategoryModel({
    required this.name,
    required this.videos,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name']?.toString() ?? '',
      videos: (json['videos'] as List<dynamic>?)
              ?.map((video) => VideoModel.fromJson(
                    Map<String, dynamic>.from(video as Map),
                  ))
              .toList() ??
          [],
    );
  }
}

/// Paginated reels feed from `/api/reels/feed`.
class ReelsFeedResult {
  const ReelsFeedResult({
    required this.reels,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.hasMore = false,
  });

  final List<VideoModel> reels;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  factory ReelsFeedResult.fromJson(dynamic json, {int? requestPage}) {
    if (json is! Map) {
      return const ReelsFeedResult(
        reels: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 0,
        hasMore: false,
      );
    }

    final root = Map<String, dynamic>.from(json);
    final reels = ReelsResponse.parseVideos(root);
    final pagination = _paginationSource(root);

    final currentPage = _int(
      pagination['current_page'] ?? root['current_page'] ?? root['page'],
      fallback: requestPage ?? 1,
    );
    final lastPage = _max(
      _int(pagination['last_page'] ?? root['last_page'], fallback: currentPage),
      currentPage,
    );

    final rawHasMore = root['has_more'] ??
        pagination['has_more'] ??
        root['hasMore'] ??
        pagination['hasMore'] ??
        (root['next_page_url'] != null || pagination['next_page_url'] != null
            ? true
            : null);

    final hasMore = rawHasMore != null
        ? VideoModel._bool(rawHasMore)
        : (currentPage < lastPage);

    return ReelsFeedResult(
      reels: reels,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: _int(pagination['per_page'] ?? root['per_page'], fallback: 10),
      total: _int(pagination['total'] ?? root['total'], fallback: reels.length),
      hasMore: hasMore,
    );
  }

  static Map<String, dynamic> _paginationSource(Map<String, dynamic> root) {
    if (root['meta'] is Map) {
      return Map<String, dynamic>.from(root['meta'] as Map);
    }

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data'] as Map);
    }

    return root;
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static int _max(int a, int b) => a > b ? a : b;
}

/// Parses reels API payloads into a flat video list.
class ReelsResponse {
  ReelsResponse._();

  static List<VideoModel> parseVideos(dynamic json) {
    if (json is List) {
      return json
          .map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    if (json is! Map) return [];

    final map = Map<String, dynamic>.from(json);

    if (map['data'] != null) {
      final data = map['data'];
      if (data is List) {
        return data
            .map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return parseVideos(data);
    }

    if (map['reels'] != null) {
      return parseVideos(map['reels']);
    }

    if (map['categories'] is List) {
      return (map['categories'] as List)
          .map((cat) => CategoryModel.fromJson(Map<String, dynamic>.from(cat as Map)))
          .expand((cat) => cat.videos)
          .toList();
    }

    if (map['videos'] is List) {
      return (map['videos'] as List)
          .map((video) => VideoModel.fromJson(Map<String, dynamic>.from(video as Map)))
          .toList();
    }

    return [];
  }
}