import 'package:flutter/src/foundation/change_notifier.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:settings/macros.dart' as settings;

void main() {
  test(
    "Creates and manipulates a Settings instance",
    () {
      final settings = Settings();
      print("${settings.duration}");
      expect(
        settings.duration,
        equals(Duration.zero),
      );
      settings.duration = const Duration(seconds: 10);
      print("${settings.duration}");
    },
  );
}

@settings.Settings()
class Settings with ChangeNotifier {
  // Brightness _brightness = Brightness.dark;
  String _id = "";
  int _number1 = 0;
  double _number2 = 0;
  Duration _duration = Duration.zero;
  Duration _duration2 = Duration.zero;
}
