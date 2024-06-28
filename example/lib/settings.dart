import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings/settings.dart';
import 'package:settings/macros.dart' as settings;

@settings.Settings()
class Settings with ChangeNotifier {
  static Settings read(BuildContext context) => context.read<Settings>();
  static Settings watch(BuildContext context) => context.watch<Settings>();

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

  Brightness _brightness = PlatformDispatcher.instance.platformBrightness;
  bool _useSystemBrightness = true;

  ThemeMode get themeMode =>
      _useSystemBrightness ? ThemeMode.system : _brightness.themeMode;
}

extension BrightnessExtension on Brightness {
  ThemeMode get themeMode => switch (this) {
        Brightness.light => ThemeMode.light,
        Brightness.dark => ThemeMode.dark,
      };
}

extension ThemeModeExtension on ThemeMode {
  Brightness? get brightness => switch (this) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        _ => null,
      };
}
