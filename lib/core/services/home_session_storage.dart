import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeSessionStorage {
  static final HomeSessionStorage _instance = HomeSessionStorage._internal();
  factory HomeSessionStorage() => _instance;
  HomeSessionStorage._internal();

  static const _storage = FlutterSecureStorage();
  static const String _homeSelectedIndexKey = 'home_selected_index';

  Future<int?> readSelectedIndex() async {
    final value = await _storage.read(key: _homeSelectedIndexKey);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> writeSelectedIndex(int index) {
    return _storage.write(key: _homeSelectedIndexKey, value: index.toString());
  }
}

