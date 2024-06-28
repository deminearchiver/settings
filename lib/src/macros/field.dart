part of 'macros.dart';

class _FieldVariables {
  const _FieldVariables({
    required this.deserialized,
    required this.serialized,
  });

  final String deserialized;
  final String serialized;
}

sealed class _Field {
  const _Field({
    required this.builder,
    required this.declaration,
    this.adapter,
  });

  final DeclarationPhaseIntrospector builder;
  final FieldDeclaration declaration;
  final ExpressionCode? adapter;

  String get rawName => declaration.identifier.name;
  String get accessorName => rawName.substring(1);
  ExpressionCode get key {
    return ExpressionCode.fromParts([
      "r\"",
      accessorName.toSnakeCase(),
      "\"",
    ]);
  }

  FutureOr<ExpressionCode?> beforeDeserialize(_FieldVariables variables) =>
      null;
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables);
  FutureOr<ExpressionCode> serialize(_FieldVariables variables);
}

class _StringField extends _Field {
  _StringField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) {
    return ExpressionCode.fromString(variables.serialized);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) {
    return ExpressionCode.fromString(variables.deserialized);
  }
}

class _BoolField extends _Field {
  _BoolField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) {
    return ExpressionCode.fromParts([
      "switch(${variables.serialized}) { ",
      "\"false\" => false, ",
      "\"true\" => true, ",
      "_ => null ",
      "}",
    ]);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) {
    return ExpressionCode.fromParts([
      "switch(${variables.deserialized}) { ",
      "false => \"false\", ",
      "true => \"true\", ",
      "}",
    ]);
  }
}

class _IntField extends _Field {
  _IntField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) async {
    final int = await builder.resolveIdentifier(_dartCore, "int");
    return ExpressionCode.fromParts([
      "${variables.serialized} != null ? ",
      int,
      ".tryParse(${variables.serialized}) : null",
    ]);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) {
    return ExpressionCode.fromString(
      "${variables.deserialized}.toString()",
    );
  }
}

class _DoubleField extends _Field {
  _DoubleField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) async {
    final double = await builder.resolveIdentifier(_dartCore, "double");
    return ExpressionCode.fromParts([
      "${variables.serialized} != null ? ",
      double,
      ".tryParse(${variables.serialized}) : null",
    ]);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) {
    return ExpressionCode.fromString(
      "${variables.deserialized}.toString()",
    );
  }
}

class _DurationField extends _Field {
  const _DurationField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  @override
  FutureOr<ExpressionCode?> beforeDeserialize(_FieldVariables variables) async {
    final int = await builder.resolveIdentifier(_dartCore, "int");
    return ExpressionCode.fromParts([
      "    final temp_${variables.serialized} = ",
      "${variables.serialized} != null ? ",
      int,
      ".tryParse(${variables.serialized}) : null;\n",
    ]);
  }

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) async {
    final duration = await builder.resolveIdentifier(_dartCore, "Duration");
    final temp = "temp_${variables.serialized}";
    return ExpressionCode.fromParts([
      "$temp != null ? ",
      duration,
      "(microseconds: $temp) : null",
    ]);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) async {
    final duration = await builder.resolveIdentifier(_dartCore, "Duration");
    final temp = "temp_${variables.serialized}";
    return ExpressionCode.fromParts([
      "${variables.deserialized}.inMicroseconds.toString()",
    ]);
  }
}

class _EnumField extends _Field {
  const _EnumField({
    required super.builder,
    required super.declaration,
    super.adapter,
  });

  Future<List<EnumValueDeclaration>> get _values async {
    final enumDeclaration = await builder.typeDeclarationOf(
      (declaration.type as NamedTypeAnnotation).identifier,
    ) as EnumDeclaration;
    return await builder.valuesOf(enumDeclaration);
  }

  @override
  FutureOr<ExpressionCode> deserialize(_FieldVariables variables) async {
    return ExpressionCode.fromParts([
      "switch(${variables.serialized}) { ",
      ...(await _values).map(
        (value) {
          return ExpressionCode.fromParts([
            value.identifier.raw,
            " => ",
            value.identifier,
            ", ",
          ]);
        },
      ),
      "_ => null ",
      "}",
    ]);
  }

  @override
  FutureOr<ExpressionCode> serialize(_FieldVariables variables) async {
    return ExpressionCode.fromParts([
      "switch(${variables.deserialized}) { ",
      ...(await _values).map(
        (value) {
          return ExpressionCode.fromParts([
            value.identifier,
            " => ",
            value.identifier.raw,
            ", ",
          ]);
        },
      ),
      "}",
    ]);
  }
}
