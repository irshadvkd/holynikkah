import 'package:holynikkah/core/utils/utils.dart';

/// One party (requester or target) attached to a phone request.
///
/// Backend payload shape is not fully fixed, so parsing is defensive and checks
/// several common key/object names for the display image and place.
class PhoneRequestParty {
  const PhoneRequestParty({
    required this.id,
    required this.imageUrl,
    this.name,
    this.place,
    this.phone,
  });

  final String id;
  final String imageUrl;
  final String? name;
  final String? place;

  /// Only present when the request is approved (the revealed number).
  final String? phone;

  bool get hasImage => imageUrl.isNotEmpty;

  bool get hasPhone => (phone?.trim().isNotEmpty ?? false);

  factory PhoneRequestParty.fromJson(Map<String, dynamic> json) {
    return PhoneRequestParty(
      id: (json['id'] ?? json['userId'] ?? json['uuid'] ?? '').toString(),
      imageUrl: mediaUrl(_parseImageUrl(json)),
      name: _firstNonEmpty(json, const ['name', 'fullName', 'full_name']),
      place: _parsePlace(json),
      phone: _firstNonEmpty(
        json,
        const ['phone', 'mobile', 'contact', 'contactNumber', 'phone_number'],
      ),
    );
  }

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

  static String? _parsePlace(Map<String, dynamic> json) {
    final flat = _firstNonEmpty(json, const ['place', 'location', 'city']);
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

/// A single phone-visibility request.
///
/// Incoming feed → requests others made for *my* phone (act via [respond]).
/// Outgoing feed → requests *I* made; approved ones expose [target]'s phone.
class PhoneRequestModel {
  const PhoneRequestModel({
    required this.id,
    required this.status,
    this.requester,
    this.target,
    this.createdAt,
  });

  final String id;

  /// `pending` | `approved` | `rejected` (lower-cased on read).
  final String status;
  final PhoneRequestParty? requester;
  final PhoneRequestParty? target;
  final String? createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  PhoneRequestModel copyWith({String? status}) => PhoneRequestModel(
        id: id,
        status: status ?? this.status,
        requester: requester,
        target: target,
        createdAt: createdAt,
      );

  factory PhoneRequestModel.fromJson(Map<String, dynamic> json) {
    return PhoneRequestModel(
      id: (json['id'] ?? json['requestId'] ?? json['request_id'] ?? '')
          .toString(),
      status: (json['status'] ?? json['state'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase(),
      requester: _party(json, const ['requester', 'from', 'sender', 'fromUser']),
      target: _party(json, const ['target', 'to', 'receiver', 'toUser']),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
    );
  }

  static PhoneRequestParty? _party(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        return PhoneRequestParty.fromJson(Map<String, dynamic>.from(value));
      }
    }
    return null;
  }
}

/// Paginated phone-requests feed (incoming or outgoing).
class PhoneRequestsResult {
  const PhoneRequestsResult({
    required this.requests,
    required this.currentPage,
    required this.lastPage,
    required this.pageSize,
    required this.total,
  });

  final List<PhoneRequestModel> requests;
  final int currentPage;
  final int lastPage;
  final int pageSize;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PhoneRequestsResult.fromJson(dynamic json) {
    if (json is List) {
      final items = _parse(json);
      return PhoneRequestsResult(
        requests: items,
        currentPage: 1,
        lastPage: 1,
        pageSize: items.length,
        total: items.length,
      );
    }

    if (json is! Map) {
      return const PhoneRequestsResult(
        requests: [],
        currentPage: 1,
        lastPage: 1,
        pageSize: 0,
        total: 0,
      );
    }

    final root = Map<String, dynamic>.from(json);

    final data = root['data'];
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      final items = _parse(inner['items'] ?? inner['data'] ?? inner);
      return _withPagination(items, inner['meta'] ?? inner);
    }

    final items = _parse(data ?? root['items'] ?? root);
    return _withPagination(items, root['meta'] ?? root);
  }

  static PhoneRequestsResult _withPagination(
    List<PhoneRequestModel> items,
    dynamic pagination,
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
    final total = _int(meta['total'], fallback: items.length);
    final lastPage = _max(
      _int(
        meta['last_page'] ?? meta['lastPage'] ?? meta['totalPages'],
        fallback: _computeLastPage(total, pageSize, currentPage),
      ),
      currentPage,
    );

    return PhoneRequestsResult(
      requests: items,
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

  static List<PhoneRequestModel> _parse(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => PhoneRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (json is Map) {
      final inner = Map<String, dynamic>.from(json);
      final list = inner['items'] ?? inner['data'] ?? inner['requests'];
      if (list is List) return _parse(list);
    }
    return const [];
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
