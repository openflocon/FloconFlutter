# flocon_files

Browse, download and delete the files of your app from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger.

## Installation

```bash
flutter pub add flocon flocon_files
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^LAST_VERSION
  flocon_files: ^LAST_VERSION
```

## Usage

```dart
import 'package:flocon_files/flocon_files.dart';

// Documents, Application Support, Caches, tmp and the app container
await startFlocon((flocon) => flocon..install(FloconFiles()));
Flocon.files.register('Exports', Directory('${docs.path}/exports'));
```

Nothing outside of the root folders is reachable.

See the [documentation](https://openflocon.github.io/Flocon/files/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
