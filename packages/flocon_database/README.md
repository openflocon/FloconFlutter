# flocon_database

Browse and query the SQLite databases of your app (sqflite, Drift, plain SQLite files) from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger, and see the queries it runs.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_database:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_database
```

## Usage

```dart
import 'package:flocon_database/flocon_database.dart';

Flocon.initialize();
await floconEnableDatabasePlugin(); // the databases, documents and application support folders
floconRegisterDatabase('Shared', '/path/to/shared.sqlite');
floconLogDatabaseQuery(path, statement, args); // from the hook of your database library
```

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
