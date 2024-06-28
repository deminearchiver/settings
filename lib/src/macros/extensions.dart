import 'package:macros/macros.dart';

final _snakeCaseRegex = RegExp(r"(?<=[a-z])[A-Z]");

extension StringExtension on String {
  String toSnakeCase() => replaceAllMapped(
        _snakeCaseRegex,
        (match) => "_${match[0]}",
      ).toLowerCase();
}

extension IdentifierExtension on Identifier {
  String get raw => "r\"$name\"";
}
