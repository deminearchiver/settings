import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';

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
    return ChangeNotifierProvider(
      create: (context) => settings,
      builder: (context, child) {
        final settings = Settings.watch(context);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settings.themeMode,
          home: const SettingsView(),
        );
      },
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final settings = Settings.watch(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text("Settings"),
          ),
          SliverList.list(
            children: [
              SwitchListTile(
                value: settings.useSystemBrightness,
                onChanged: (value) => settings.useSystemBrightness = value,
                secondary: const Icon(Symbols.auto_mode_rounded),
                title: const Text("Use system brightness"),
              ),
              SegmentedButton<Brightness>(
                onSelectionChanged: (values) =>
                    settings.brightness = values.first,
                selected: {settings.brightness},
                segments: const [
                  ButtonSegment(
                    value: Brightness.light,
                    icon: Icon(Symbols.light_mode_rounded),
                    label: Text("Light"),
                  ),
                  ButtonSegment(
                    value: Brightness.dark,
                    icon: Icon(Symbols.dark_mode_rounded),
                    label: Text("Dark"),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
