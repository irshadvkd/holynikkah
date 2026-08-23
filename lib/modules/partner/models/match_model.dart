import 'package:holynikkah/core/utils/utils.dart';

/// A single match in the matrimony feed.
///
/// Normal feed → active female normal users surfaced via their default saved
/// template (the rendered preview image). VIP feed → active female VIP users.
/// The backend response shape is not fully fixed, so parsing is intentionally
/// defensive and checks several common key/object names for the display image.
class MatchModel {
  const MatchModel({
    required this.id,
    required this.imageUrl,
    this.name,
    this.age,
    this.place,
    this.phone,
    this.phoneAccess,
  });

  final String id;

  /// Fully-qualified image to render full-screen — the rendered default
  /// template preview (`profile.previewImage`).
  final String imageUrl;
  final String? name;
  final String? age;
  final String? place;

  /// Contact number, only present when the match has shared/approved it.
  /// `null` when hidden — the viewer must request access first.
  final String? phone;

  /// Phone-visibility state for the viewer: `granted` | `visible` | `pending`
  /// | `none`. `pending` means a contact request was already sent and is
  /// awaiting approval (lower-cased on read).
  final String? phoneAccess;

  bool get hasImage => imageUrl.isNotEmpty;

  /// Whether a dialable contact number is available for this match.
  bool get hasPhone => (phone?.trim().isNotEmpty ?? false);

  /// Whether a contact request was already sent and is awaiting approval —
  /// the viewer should not be able to request again.
  bool get isRequestPending => phoneAccess == 'pending';

  /// Returns a copy with [phone]/[phoneAccess] set — used after a contact
  /// request is granted (phone) or queued (pending).
  MatchModel copyWith({String? phone, String? phoneAccess}) => MatchModel(
        id: id,
        imageUrl: imageUrl,
        name: name,
        age: age,
        place: place,
        phone: phone ?? this.phone,
        phoneAccess: phoneAccess ?? this.phoneAccess,
      );

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    // The feed wraps each match in a `profile` object alongside `updatedAt`.
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;

    return MatchModel(
      id: (profile['id'] ?? profile['userId'] ?? profile['uuid'] ?? '')
          .toString(),
      imageUrl: mediaUrl(_parseImageUrl(profile)),
      name: _firstNonEmpty(profile, const ['name', 'fullName', 'full_name']),
      age: _firstNonEmpty(profile, const ['age']),
      place: _parsePlace(profile),
      phone: _firstNonEmpty(
        profile,
        const ['phone', 'mobile', 'contact', 'contactNumber', 'phone_number'],
      ),
      phoneAccess: _firstNonEmpty(
        profile,
        const ['phoneAccess', 'phone_access'],
      )?.toLowerCase(),
    );
  }

  /// Fullscreen image is the default-template preview; fall back to the user's
  /// own photo only when no template preview exists.
  static String _parseImageUrl(Map<String, dynamic> json) {
    const imageKeys = [
      'previewImage',
      'preview_image',
      'imageUrl',
      'image_url',
      'image',
      'photo',
      'thumbnail',
      'thumbnail_url',
      'picture',
    ];

    final direct = _firstNonEmpty(json, imageKeys);
    if (direct != null) return direct;

    const nestedKeys = [
      'defaultTemplate',
      'default_template',
      'savedTemplate',
      'saved_template',
      'template',
    ];
    for (final key in nestedKeys) {
      final nested = json[key];
      if (nested is Map) {
        final value =
            _firstNonEmpty(Map<String, dynamic>.from(nested), imageKeys);
        if (value != null) return value;
      }
    }
    return '';
  }

  /// Prefers `city`, falling back to the nested `district`/`state` name.
  static String? _parsePlace(Map<String, dynamic> json) {
    final flat = _firstNonEmpty(
      json,
      const ['place', 'location', 'city'],
    );
    if (flat != null) return flat;

    for (final key in const ['district', 'state']) {
      final nested = json[key];
      if (nested is Map) {
        final name = (nested['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    }
    return null;
  }

  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}

/// Paginated matches feed from `/{tier}-users/matches`.
class MatchesFeedResult {
  const MatchesFeedResult({
    required this.matches,
    required this.currentPage,
    required this.lastPage,
    required this.pageSize,
    required this.total,
  });

  final List<MatchModel> matches;
  final int currentPage;
  final int lastPage;
  final int pageSize;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory MatchesFeedResult.fromJson(dynamic json) {
    if (json is List) {
      final items = _parseMatches(json);
      return MatchesFeedResult(
        matches: items,
        currentPage: 1,
        lastPage: 1,
        pageSize: items.length,
        total: items.length,
      );
    }

    if (json is! Map) {
      return const MatchesFeedResult(
        matches: [],
        currentPage: 1,
        lastPage: 1,
        pageSize: 0,
        total: 0,
      );
    }

    final root = Map<String, dynamic>.from(json);

    // `{ data: { items: [...], meta: {...} } }`
    final data = root['data'];
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      final items = _parseMatches(inner['items'] ?? inner['data'] ?? inner);
      return _withPagination(items, inner['meta'] ?? inner, root);
    }

    // `{ data: [...], meta: {...} }`
    final items = _parseMatches(data ?? root['items'] ?? root);
    return _withPagination(items, root['meta'] ?? root, root);
  }

  static MatchesFeedResult _withPagination(
    List<MatchModel> items,
    dynamic pagination,
    Map<String, dynamic> root,
  ) {
    final meta = pagination is Map
        ? Map<String, dynamic>.from(pagination)
        : <String, dynamic>{};

    final currentPage = _int(
      meta['current_page'] ?? meta['currentPage'] ?? meta['page'],
      fallback: 1,
    );
    final pageSize = _int(
      meta['per_page'] ?? meta['perPage'] ?? meta['pageSize'],
      fallback: items.isEmpty ? 10 : items.length,
    );
    final total = _int(
      meta['total'],
      fallback: items.length,
    );
    final lastPage = _max(
      _int(
        meta['last_page'] ?? meta['lastPage'] ?? meta['totalPages'],
        fallback: _computeLastPage(total, pageSize, currentPage),
      ),
      currentPage,
    );

    return MatchesFeedResult(
      matches: items,
      currentPage: currentPage,
      lastPage: lastPage,
      pageSize: pageSize,
      total: total,
    );
  }

  static int _computeLastPage(int total, int pageSize, int currentPage) {
    if (pageSize <= 0) return currentPage;
    final pages = (total / pageSize).ceil();
    return pages < 1 ? currentPage : pages;
  }

  static List<MatchModel> _parseMatches(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => MatchModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (json is Map) {
      final inner = Map<String, dynamic>.from(json);
      final list = inner['items'] ?? inner['data'] ?? inner['matches'];
      if (list is List) return _parseMatches(list);
    }
    return const [];
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
