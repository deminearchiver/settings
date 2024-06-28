import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:settings/macros.dart' as settings;
import 'package:settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // test(
  //   "Creates and manipulates a Settings instance",
  //   () {},
  // );
}

@settings.Settings()
class Settings with ChangeNotifier {
  Settings({
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
  }) : _adapters = {
          "memory": const MemorySettingsAdapter(),
          "shared": SharedSettingsAdapter(sharedPreferences),
          "secure": SecureSettingsAdapter(secureStorage),
        };

  final Map<String, SettingsAdapter> _adapters;

  SettingsAdapter _adapterFor([String? kind]) {
    return kind != null && _adapters.containsKey(kind)
        ? _adapters[kind]!
        : _adapters["shared"]!;
  }

  Brightness _brightness = Brightness.dark;

  @settings.Adapter("secure")
  String _password = "";

  bool _useSystemBrightness = true;
  String _id = "";
  int _number1 = 0;
  double _number2 = 0;
  Duration _duration = Duration.zero;
  Duration _duration2 = Duration.zero;
}
