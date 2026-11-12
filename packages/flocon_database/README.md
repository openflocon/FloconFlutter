# flocon_database

Browse and query the SQLite databases of your app (sqflite, Drift, plain SQLite files) from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger, and see the queries it runs.

## Installation

```bash
flutter pub add flocon flocon_database
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^LAST_VERSION
  flocon_database: ^LAST_VERSION
```

## Usage

```dart
import 'package:flocon_database/flocon_database.dart';

// the databases, documents and application support folders
await startFlocon((flocon) => flocon..install(FloconDatabase()));
Flocon.database.register('Shared', '/path/to/shared.sqlite');
Flocon.database.logQuery(path, statement, args); // from the hook of your database library
```

See the [documentation](https://openflocon.github.io/Flocon/database/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
