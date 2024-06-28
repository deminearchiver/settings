import 'dart:async';

import 'package:macros/macros.dart';
import 'package:collection/collection.dart';
import 'package:settings/settings.dart';
import 'extensions.dart';

part 'field.dart';

final _dartCore = Uri.parse("dart:core");
final _dartAsync = Uri.parse("dart:async");
final _changeNotifier =
    Uri.parse("package:flutter/src/foundation/change_notifier.dart");

final _settings = Uri.parse("package:settings/settings.dart");
final _annotations = Uri.parse("package:settings/src/macros/annotations.dart");

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
    if(!await _checkAdapterFor(clazz, builder, builder)) return;

    final fields = await _getFields(clazz, builder);
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
    if (data == null) return;

    final methods = await builder.methodsOf(clazz);
    final map = await data
        .map((field) => methods
            .where((method) => method.identifier.name == field.accessorName)
            .map(
              (method) async => _Method(
                builder: await builder.buildMethod(method.identifier),
                field: field,
                method: method,
              ),
            ))
        .flattened
        .wait;
    for (final method in map) {
      final isGetter = method.method.isGetter;

      if (isGetter) {
      } else {}

      method.builder.augment(
        isGetter
            ? FunctionBodyCode.fromParts([" => ${method.field.rawName};"])
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
    final future = await builder.resolveIdentifier(_dartAsync, "Future");
    final futureOr = await builder.resolveIdentifier(_dartAsync, "FutureOr");
    final list = await builder.resolveIdentifier(_dartCore, "List");

    final load =
        methods.firstWhereOrNull((method) => method.identifier.name == "load");
    if (load != null) {
      final loadBuilder = await builder.buildMethod(load.identifier);
      loadBuilder.augment(
        FunctionBodyCode.fromParts([
          "async {\n",
          "    final [\n",
          ...data
            .map(
              (field) => "      s_${field.accessorName},\n",
            ),
          "    ] = await ",
          future,
          ".wait([\n",
          ...data.map(
            (field) {
              return ExpressionCode.fromParts([
                "      _adapterFor(",
                if(field.adapter != null) field.adapter!,
                ").read(",
                field.key,
                "),\n",   
              ]);
            },
          ),
          "    ] as ",
          list,
          "<",
          future,
          "<",
          string,
          "?>>);\n\n",
          ...await data.map(
            (field) async {
              final variables = _FieldVariables(
                deserialized: "d_${field.accessorName}",
                serialized: "s_${field.accessorName}",
              );
              final beforeDeserialize =
                  await field.beforeDeserialize(variables);
              return ExpressionCode.fromParts([
                if (beforeDeserialize != null) beforeDeserialize,
                "    final ${variables.deserialized} = ",
                await field.deserialize(variables),
                ";\n",
                "    if(${variables.deserialized} != null) ${field.rawName} = ${variables.deserialized};\n\n",
              ]);
            },
          ).wait,
          "    if(",
          data.map((field) => "d_${field.accessorName} != null").join(" &&\n       "),
          ") notifyListeners();\n",
          "  }",
        ]),
        docComments:
            CommentCode.fromString("  /// Loads all values from storage."),
      );
    }

    final save =
        methods.firstWhereOrNull((method) => method.identifier.name == "save");
    if (save != null) {
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
          "\n    await ",
          future,
          ".wait([\n",
          ...data.map(
            (field) {
              final serialized = "s_${field.accessorName}";
              return ExpressionCode.fromParts([
                "      _adapterFor(",
                if(field.adapter != null) field.adapter!,
                ").write(",
                field.key,
                ", $serialized),\n",   
              ]);
            },
          ),
          "    ] as ",
          list,
          "<",
          future,
          "<void>>);\n",
          "  }",
        ]),
        docComments:
            CommentCode.fromString("  /// Saves all values to storage."),
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

const Set<String> _kDefaultFieldNames = {
  "_defaultAdapter",
  "_adapters",
};

mixin _Shared {
  Future<Iterable<FieldDeclaration>> _getFields(
    ClassDeclaration clazz,
    DeclarationPhaseIntrospector builder,
  ) async {
    final fields = await builder.fieldsOf(clazz);
    return fields
        .whereNot(
          (field) => _kDefaultFieldNames.contains(field.identifier.name),
        )
        .where(
          (field) => field.identifier.name.startsWith("_"),
        );
  }

  Future<List<_Field>?> _buildFields(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {


    final (
      string,
      bool,
      int,
      double,
      duration,
    ) = await (
      builder.resolveIdentifier(_dartCore, "String"),
      builder.resolveIdentifier(_dartCore, "bool"),
      builder.resolveIdentifier(_dartCore, "int"),
      builder.resolveIdentifier(_dartCore, "double"),
      builder.resolveIdentifier(_dartCore, "Duration"),
    ).wait;
    final (
      stringType,
      boolType,
      intType,
      doubleType,
      durationType,
    ) = await (
      builder.resolve(NamedTypeAnnotationCode(name: string)),
      builder.resolve(NamedTypeAnnotationCode(name: bool)),
      builder.resolve(NamedTypeAnnotationCode(name: int)),
      builder.resolve(NamedTypeAnnotationCode(name: double)),
      builder.resolve(NamedTypeAnnotationCode(name: duration)),
    ).wait;

    final fields = await _getFields(clazz, builder);
    final result = <_Field>[];
    for (final field in fields) {
      final adapter = await _getAdapter(field, builder, builder);

      final type = field.type;
      if (type is! NamedTypeAnnotation) {
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

      final declaration = await builder.typeDeclarationOf(type.identifier);
      if (await staticType.isExactly(stringType)) {
        result.add(
          _StringField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      } else if (await staticType.isExactly(boolType)) {
        result.add(
          _BoolField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      } else if (await staticType.isExactly(intType)) {
        result.add(
          _IntField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      } else if (await staticType.isExactly(doubleType)) {
        result.add(
          _DoubleField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      } else if (await staticType.isExactly(durationType)) {
        result.add(
          _DurationField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      } else if (declaration is EnumDeclaration) {
        result.add(
          _EnumField(
            builder: builder,
            declaration: field,
            adapter: adapter,
          ),
        );
      }
    }
    return result;
  }

  Future<ExpressionCode?> _getAdapter(
    FieldDeclaration field,
    DeclarationPhaseIntrospector builder,
    Builder reporter,
  ) async {
    final adapter = await builder.resolveIdentifier(_annotations, "Adapter");
    final adapterType = await builder.resolve(NamedTypeAnnotationCode(name: adapter));

    final adapters = <ConstructorMetadataAnnotation>{};
    for(final annotation in field.metadata) {
      if(annotation is! ConstructorMetadataAnnotation) continue;
      final staticType = await builder.resolve(annotation.type.code);
      if(await staticType.isExactly(adapterType)) {
        adapters.add(annotation);
      }
    }
    if(adapters.length > 1) {
      reporter.report(
        Diagnostic(
          DiagnosticMessage(
            "Too many `Adapter` annotations. The default adapter will be used.",
            target: field.asDiagnosticTarget,
          ),
          Severity.warning,
          correctionMessage: "Try removing all but one `Adapter` annotation",
        ),
      );
      return null;
    }
    return adapters.singleOrNull?.positionalArguments.single;
  }

  Future<bool> _checkAdapterFor(
    ClassDeclaration clazz,
    DeclarationPhaseIntrospector builder,
    Builder reporter,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final adapterFor = methods.firstWhereOrNull(
      (method) => method.identifier.name == "_adapterFor",
    );

    if(adapterFor == null) {
      reporter.report(
        Diagnostic(
          DiagnosticMessage("`_adapterFor` method not found or has invalid type"),
          Severity.error,
          correctionMessage: "Create a `_adapterFor` method: SettingsAdapter _adapterFor([SettingsAdapterKind? kind])",
        ),
      );
      return false;
    }

    final invalidSignatureMessage = DiagnosticMessage(
      "Invalid signature",
      target: adapterFor.asDiagnosticTarget,
    );

    if(
      adapterFor.positionalParameters.length != 1 ||
      adapterFor.namedParameters.isNotEmpty ||
      adapterFor.typeParameters.isNotEmpty
    ) {
      reporter.report(
        Diagnostic(
          DiagnosticMessage(
            "Must have exactly one positional parameter of type `SettingsAdapterKind`",
            target: adapterFor.asDiagnosticTarget,
          ),
          Severity.error,
          contextMessages: [invalidSignatureMessage],
        ),
      );
      return false;
    }

    if(adapterFor.returnType.isNullable) {
      reporter.report(
        Diagnostic(
          DiagnosticMessage(
            "Return type must not be nullable",
            target: adapterFor.asDiagnosticTarget,
          ),
          Severity.error,
          contextMessages: [invalidSignatureMessage],

        ),
      );
      return false;
    }

    // TODO: add more checks, especially checks for correct types

    return true;
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
    for (final mixin in clazz.mixins) {
      final mixinType = await builder.resolve(mixin.code);
      if (await mixinType.isSubtypeOf(changeNotifierType)) {
        hasChangeNotifier = true;
        break;
      }
    }
    return hasChangeNotifier;
  }
}
