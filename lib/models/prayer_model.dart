import 'package:holynikkah/core/utils/utils.dart';

class PrayerModel {
  const PrayerModel({
    this.id,
    required this.imageUrl,
    this.title,
    this.status,
    this.isWatched = false,
    this.mediaType = 'image',
    this.mediaPath,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String imageUrl;
  final String? title;
  final String? status;
  final bool isWatched;
  final String mediaType;
  final String? mediaPath;
  final String? createdAt;
  final String? updatedAt;

  PrayerModel copyWith({
    int? id,
    String? imageUrl,
    String? title,
    String? status,
    bool? isWatched,
    String mediaType = 'image',
    String? mediaPath,
    String? createdAt,
    String? updatedAt,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      status: status ?? this.status,
      isWatched: isWatched ?? this.isWatched,
      mediaType: mediaType,
      mediaPath: mediaPath ?? this.mediaPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      imageUrl: mediaUrl(_parseImageUrl(json)),
      title: json['title']?.toString(),
      status: json['status']?.toString(),
      isWatched: _bool(json['is_watched'] ?? json['watched']),
      mediaType: json['media_type']?.toString() ?? 'image',
      mediaPath: json['media_path']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static String _parseImageUrl(Map<String, dynamic> json) {
    return _string(
      json['media_url'] ??
          json['media_path'] ??
          json['image'] ??
          json['image_url'] ??
          json['url'] ??
          json['thumb'] ??
          json['thumbnail'] ??
          json['thumbnail_url'] ??
          json['file'],
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
}

/// Paginated prayers feed from `/api/prayers/feed` and common ad feeds.
class PrayersFeedResult {
  const PrayersFeedResult({
    required this.prayers,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.hasMore = false,
  });

  final List<PrayerModel> prayers;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  factory PrayersFeedResult.fromJson(dynamic json, {int? requestPage}) {
    if (json is! Map) {
      return const PrayersFeedResult(
        prayers: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 0,
        hasMore: false,
      );
    }

    final root = Map<String, dynamic>.from(json);
    final prayers = PrayersResponse.parsePrayers(root);
    final pagination = _paginationSource(root);

    final currentPage = _int(
      pagination['current_page'] ?? root['current_page'] ?? root['page'],
      fallback: requestPage ?? 1,
    );
    final lastPage = _max(
      _int(pagination['last_page'] ?? root['last_page'], fallback: currentPage),
      currentPage,
    );

    final links = root['links'] is Map
        ? Map<String, dynamic>.from(root['links'] as Map)
        : null;
    final rawHasMore = root['has_more'] ??
        pagination['has_more'] ??
        root['hasMore'] ??
        pagination['hasMore'] ??
        (root['next_page_url'] != null ||
                pagination['next_page_url'] != null ||
                (links != null && links['next'] != null)
            ? true
            : null);

    final hasMore = rawHasMore != null
        ? PrayerModel._bool(rawHasMore)
        : (currentPage < lastPage);

    return PrayersFeedResult(
      prayers: prayers,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: _int(pagination['per_page'] ?? root['per_page'], fallback: 10),
      total: _int(pagination['total'] ?? root['total'], fallback: prayers.length),
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

class PrayersResponse {
  PrayersResponse._();

  static List<PrayerModel> parsePrayers(dynamic json) {
    if (json is List) {
      return json
          .map(
            (item) => PrayerModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (json is! Map) return [];

    final map = Map<String, dynamic>.from(json);

    if (map['data'] != null) {
      final data = map['data'];
      if (data is List) {
        return data
            .map(
              (item) => PrayerModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      return parsePrayers(data);
    }

    if (map['prayers'] is List) {
      return (map['prayers'] as List)
          .map(
            (item) => PrayerModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return [];
  }
}
