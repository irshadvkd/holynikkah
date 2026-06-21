class LocationState {
  const LocationState({
    required this.id,
    required this.name,
    this.status,
  });

  final int id;
  final String name;
  final String? status;

  factory LocationState.fromJson(Map<String, dynamic> json) {
    return LocationState(
      id: _int(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LocationDistrict {
  const LocationDistrict({
    required this.id,
    required this.stateId,
    required this.name,
    this.status,
  });

  final int id;
  final int stateId;
  final String name;
  final String? status;

  factory LocationDistrict.fromJson(Map<String, dynamic> json) {
    return LocationDistrict(
      id: _int(json['id']) ?? 0,
      stateId: _int(json['state_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationDistrict && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LocationsResponse {
  LocationsResponse._();

  static List<LocationState> parseStates(dynamic json) {
    return _extractItems(json)
        .where(_isActive)
        .map((item) => LocationState.fromJson(Map<String, dynamic>.from(item)))
        .where((state) => state.id > 0 && state.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<LocationDistrict> parseDistricts(dynamic json) {
    return _extractItems(json)
        .where(_isActive)
        .map(
          (item) => LocationDistrict.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((district) => district.id > 0 && district.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<dynamic> _extractItems(dynamic json) {
    if (json is List) return json;
    if (json is Map && json['data'] is List) {
      return json['data'] as List;
    }
    return [];
  }

  static bool _isActive(dynamic item) {
    if (item is! Map) return true;
    final status = item['status']?.toString().toLowerCase();
    return status == null || status == 'active';
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value');
}
