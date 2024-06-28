import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingsAdapterKind {
  memory("memory"),
  shared("shared"),
  secure("secure");

  const SettingsAdapterKind(this.name);

  final String name;
}

abstract class SettingsAdapter {
  const SettingsAdapter();

  FutureOr<String?> read(String key);
  FutureOr<void> write(String key, String value);
}

class MemorySettingsAdapter extends SettingsAdapter {
  const MemorySettingsAdapter() : _values = const {};

  final Map<String, String> _values;

  @override
  FutureOr<String?> read(String key) {
    return _values[key];
  }

  @override
  FutureOr<void> write(String key, String value) {
    _values[key] = value;
  }
}

class SharedSettingsAdapter extends SettingsAdapter {
  SharedSettingsAdapter(this._preferences);

  final SharedPreferences _preferences;

  @override
  FutureOr<String?> read(String key) {
    return _preferences.getString(key);
  }

  @override
  FutureOr<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

class SecureSettingsAdapter extends SettingsAdapter {
  SecureSettingsAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  FutureOr<String?> read(String key) {
    return _storage.read(
      key: key,
    );
  }

  @override
  FutureOr<void> write(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
    );
  }
}
