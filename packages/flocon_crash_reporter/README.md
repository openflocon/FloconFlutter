# flocon_crash_reporter

Sends the uncaught Dart and Flutter errors of your app, with their stack trace, to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger. The handlers already set (Crashlytics, Sentry...) keep working.

## Installation

```bash
flutter pub add flocon flocon_crash_reporter
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^LAST_VERSION
  flocon_crash_reporter: ^LAST_VERSION
```

## Usage

```dart
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';

await startFlocon((flocon) => flocon..install(FloconCrashReporter()));
```

Errors are saved on disk and sent on the next connection, even after a restart. Native crashes are not reported.

See the [documentation](https://openflocon.github.io/Flocon/crashreporter/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
