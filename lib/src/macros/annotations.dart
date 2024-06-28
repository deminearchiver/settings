import 'package:meta/meta_meta.dart';
import 'package:settings/settings.dart';

@Target({TargetKind.field})
class Key {
  const Key(this.key);

  final String key;
}

@Target({TargetKind.field})
class Adapter {
  const Adapter(this.adapter);

  final String adapter;
}

@Target({TargetKind.field})
class Ignore {
  const Ignore();
}
