import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:settings/macros.dart' as settings;
import 'package:settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Brightness _brightness = PlatformDispatcher.instance.platformBrightness;
  bool _useSystemBrightness = true;
}

void main() async {
  final settings = Settings(
    sharedPreferences: await SharedPreferences.getInstance(),
    secureStorage: const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ),
  );
  await settings.load();

  runApp(
    App(settings: settings),
  );
}

class App extends StatelessWidget {
  const App({
    super.key,
    required this.settings,
  });

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
    );
  }
}
