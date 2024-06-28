import 'dart:async';

import 'package:macros/macros.dart';
import 'package:collection/collection.dart';


import 'annotations.dart';
import 'extensions.dart';

part 'field.dart';

final _dartCore = Uri.parse("dart:core");
final _dartAsync = Uri.parse("dart:async");
final _changeNotifier =
    Uri.parse("package:flutter/src/foundation/change_notifier.dart");

final _settings = Uri.parse("package:settings/settings.dart");
final _macros = Uri.parse("package:settings/macros.dart");

void _log(Builder builder, String message, [DiagnosticTarget? target]) {
  builder.report(
    Diagnostic(
      DiagnosticMessage(message, target: target),
      Severity.info,
    ),
  );
}

macro class Settings
    with _Shared
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const Settings();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final fields = (await builder.fieldsOf(clazz)).where(
      (field) => field.identifier.name.startsWith("_"),
    );
    for (final field in fields) {
      final rawName = field.identifier.name;
      final accessorName = rawName.substring(1);

      builder.declareInType(
        DeclarationCode.fromParts([
          "  external ",
          field.type.code,
          " get $accessorName;",
        ]),
      );
      builder.declareInType(
        DeclarationCode.fromParts([
          "  external set $accessorName(",
          field.type.code,
          " value);",
        ]),
      );
    }
    // builder.declareInType(
    //   DeclarationCode.fromParts([
    //     "  ",
    //     future,
    //     "<void> load() async {\n",
    //     ...await data.map(
    //       (field) async {
    //         final variables = _FieldVariables(
    //           deserialized: "d_${field.accessorName}",
    //           serialized: "s_${field.accessorName}",
    //         );
    //         final beforeDeserialize = await field.beforeDeserialize(variables);
    //         return ExpressionCode.fromParts([
    //           "    final ${variables.serialized} = '';\n",
    //           if (beforeDeserialize != null) beforeDeserialize,
    //           "    final ${variables.deserialized} = ",
    //           await field.deserialize(variables),
    //           ";\n",
    //           "    if(${variables.deserialized} != null) ${field.rawName} = ${variables.deserialized};\n",
    //         ]);
    //       },
    //     ).wait,
    //     "  }",
    //   ]),
    // );

    // builder.declareInType(
    //   DeclarationCode.fromParts([
    //     "  ",
    //     future,
    //     "<void> save() async {\n",
    //     ...await data.map(
    //       (field) async {
    //         final variables = _FieldVariables(
    //           deserialized: field.rawName,
    //           serialized: "s_${field.accessorName}",
    //         );
    //         return ExpressionCode.fromParts([
    //           "    final ${variables.serialized} = ",
    //           await field.serialize(variables),
    //           ";\n",
    //         ]);
    //       },
    //     ).wait,
    //     "  }",
    //   ]),
    // );

    final future = await builder.resolveIdentifier(_dartAsync, "Future");

    builder.declareInType(
      DeclarationCode.fromParts([
        "  external ",
        future,
        "<void> load();",
      ]),
    );

    builder.declareInType(
      DeclarationCode.fromParts([
        "  external ",
        future,
        "<void> save();",
      ]),
    );
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {

    final data = await _buildFields(clazz, builder);
    if(data == null) return;

    final methods = await builder.methodsOf(clazz);
    final map = await data
      .map(
        (field) =>
          methods.where(
            (method) => method.identifier.name == field.accessorName
          )
          .map(
            (method) async => _Method(
              builder: await builder.buildMethod(method.identifier),
              field: field,
              method: method,
            ),
          )
        )
        .flattened
        .wait;
    for(final method in map) {
      final isGetter = method.method.isGetter;

      if(isGetter) {

      } else {

      }

      method.builder.augment(
        isGetter
          ? FunctionBodyCode.fromParts([
            " => ${method.field.rawName};"
          ])
          : FunctionBodyCode.fromParts([
            "{\n",
            "    ${method.field.rawName} = value;\n",
            "    notifyListeners();\n",
            "    save();\n",
            "  }",
          ]),
      );
    }

    final string = await builder.resolveIdentifier(_dartCore, "String");

    final load = methods.firstWhereOrNull((method) => method.identifier.name == "load");
    if(load != null) {
      final loadBuilder = await builder.buildMethod(load.identifier);
      loadBuilder.augment(
        FunctionBodyCode.fromParts([
          "async {\n",
          ...await data.map(
            (field) async {
              final variables = _FieldVariables(
                deserialized: "d_${field.accessorName}",
                serialized: "s_${field.accessorName}",
              );
              final beforeDeserialize = await field.beforeDeserialize(variables);
              return ExpressionCode.fromParts([
                "    final ",
                string,
                " ${variables.serialized} = '';\n",
                if (beforeDeserialize != null) beforeDeserialize,
                "    final ${variables.deserialized} = ",
                await field.deserialize(variables),
                ";\n",
                "    if(${variables.deserialized} != null) ${field.rawName} = ${variables.deserialized};\n\n",
              ]);
            },
          ).wait,
          "    if(",
          data
            .map(
              (field) => "d_${field.accessorName} != null"
            )
            .join(" && "),
          ") notifyListeners();\n",
          "  }",
        ]),
      );
    }

    final save = methods.firstWhereOrNull((method) => method.identifier.name == "save");
    if(save != null) {
      final saveBuilder = await builder.buildMethod(save.identifier);
      saveBuilder.augment(
        FunctionBodyCode.fromParts([
          "async {\n",
          ...await data.map(
            (field) async {
              final variables = _FieldVariables(
                deserialized: field.rawName,
                serialized: "s_${field.accessorName}",
              );
              return ExpressionCode.fromParts([
                "    final ${variables.serialized} = ",
                await field.serialize(variables),
                ";\n",
              ]);
            },
          ).wait,
          "  }",
        ]),
      );
    }
  }
}

class _Method {
  const _Method({
    required this.builder,
    required this.field,
    required this.method,
  });
  final FunctionDeclaration method;
  final _Field field;
  final FunctionDefinitionBuilder builder;
}

mixin _Shared {
  Future<List<_Field>?> _buildFields(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final (
      string,
      int,
      double,
      duration,
    ) = await (
      builder.resolveIdentifier(_dartCore, "String"),
      builder.resolveIdentifier(_dartCore, "int"),
      builder.resolveIdentifier(_dartCore, "double"),
      builder.resolveIdentifier(_dartCore, "Duration"),
    ).wait;
    final (
      stringType,
      intType,
      doubleType,
      durationType,
    ) = await (
      builder.resolve(NamedTypeAnnotationCode(name: string)),
      builder.resolve(NamedTypeAnnotationCode(name: int)),
      builder.resolve(NamedTypeAnnotationCode(name: double)),
      builder.resolve(NamedTypeAnnotationCode(name: duration)),
    ).wait;

    final fields = (await builder.fieldsOf(clazz))
      .where(
        (field) => field.identifier.name.startsWith("_"),
      );
    final result = <_Field>[];
    for(final field in fields) {
      final type = field.type;
      if(type is! NamedTypeAnnotation) {
        builder.report(
          Diagnostic(
            DiagnosticMessage(
              "Field must have named type",
              target: field.asDiagnosticTarget,
            ),
            Severity.error,
          ),
        );
        return null;
      }
      final staticType = await builder.resolve(type.code);

      // final declaration = await builder.typeDeclarationOf(type.identifier);
      // if(await staticType.isExactly(enumType)) {
        // result.add(
        //   _EnumField(
        //     builder: builder,
        //     declaration: field,
        //   ),
        // );
      // } else 
      if(await staticType.isExactly(stringType)) {
        result.add(
          _StringField(
            builder: builder,
            declaration: field,
          ),
        );
      } else if(await staticType.isExactly(intType)) {
        result.add(
          _IntField(
            builder: builder,
            declaration: field,
          ),
        );
      } else if(await staticType.isExactly(doubleType)) {
        result.add(
          _DoubleField(
            builder: builder,
            declaration: field,
          ),
        );
      } else if(await staticType.isExactly(durationType)) {
        result.add(
          _DurationField(
            builder: builder,
            declaration: field,
          ),
        );
      }
    }
    return result;
  }
  Future<bool> _checkHasChangeNotifier(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final changeNotifier = await builder.resolveIdentifier(
      _changeNotifier,
      "ChangeNotifier",
    );
    final changeNotifierType = await builder.resolve(
      NamedTypeAnnotationCode(name: changeNotifier),
    );

    bool hasChangeNotifier = false;
    for(final mixin in clazz.mixins) {
      final mixinType = await builder.resolve(mixin.code);
      if(await mixinType.isSubtypeOf(changeNotifierType)) {
        hasChangeNotifier = true;
        break;
      }
    }
    return hasChangeNotifier;
  }
}
