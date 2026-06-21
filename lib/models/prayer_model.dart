import 'package:holynikkah/core/utils/constants.dart';

class PrayerModel {
  const PrayerModel({
    this.id,
    required this.imageUrl,
    this.isWatched = false,
  });

  final int? id;
  final String imageUrl;
  final bool isWatched;

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      imageUrl: _normalizeUrl(_parseImageUrl(json)),
      isWatched: _bool(json['is_watched'] ?? json['watched']),
    );
  }

  static String _parseImageUrl(Map<String, dynamic> json) {
    return _string(
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

  static String _normalizeUrl(String url) {
    if (url.isEmpty) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      final base = Uri.parse(AppConstants.urls.base);
      return uri.replace(host: base.host, port: base.port).toString();
    }
    return url;
  }
}

/// Paginated prayers feed from `/api/prayers/feed`.
class PrayersFeedResult {
  const PrayersFeedResult({
    required this.prayers,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<PrayerModel> prayers;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PrayersFeedResult.fromJson(dynamic json) {
    if (json is! Map) {
      return const PrayersFeedResult(
        prayers: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 0,
      );
    }

    final root = Map<String, dynamic>.from(json);
    final prayers = PrayersResponse.parsePrayers(root);
    final pagination = _paginationSource(root);

    final currentPage = _int(pagination['current_page'], fallback: 1);
    final lastPage = _max(
      _int(pagination['last_page'], fallback: currentPage),
      currentPage,
    );

    return PrayersFeedResult(
      prayers: prayers,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: _int(pagination['per_page'], fallback: 10),
      total: _int(pagination['total'], fallback: prayers.length),
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
