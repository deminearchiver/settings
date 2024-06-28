<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Settings

This package contains a [**macro**](https://dart.dev/language/macros) which simplifies the creation of a *"settings"* structure in your Flutter apps.

It supports pre-configured and custom adapters for persisting data.
- shared_preferences
- flutter_secure_storage

## Features

- Multiple adapters
- Automatic support for [`ChangeNotifier`](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

#### Without a version manager
```sh
flutter channel master
```

#### If using Puro
```sh
puro create main --channel=main # or: puro create master
puro use main
```

## Usage

```dart
// settings.dart
import 'package:flutter/foundation.dart';

import 'package:settings/macros.dart' as settings;

@settings.Settings()
class Settings with ChangeNotifier {

}
```

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
