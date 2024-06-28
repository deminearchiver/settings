import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsAdapterKind {}

enum BuiltInSettingsAdapter implements SettingsAdapterKind {
  memory,
  shared,
  secure;
}

abstract class SettingsAdapter {
  const SettingsAdapter();

  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemorySettingsAdapter extends SettingsAdapter {
  const MemorySettingsAdapter() : _values = const {};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class SharedSettingsAdapter extends SettingsAdapter {
  SharedSettingsAdapter(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> read(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

class SecureSettingsAdapter extends SettingsAdapter {
  SecureSettingsAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _storage.read(
      key: key,
    );
  }

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
    );
  }
}
