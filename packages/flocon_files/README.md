# flocon_files

Browse, download and delete the files of your app from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_files:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_files
```

## Usage

```dart
import 'package:flocon_files/flocon_files.dart';

// Documents, Application Support, Caches, tmp and the app container
await startFlocon((flocon) => flocon..install(FloconFiles()));
Flocon.files.register('Exports', Directory('${docs.path}/exports'));
```

Nothing outside of the root folders is reachable.

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
