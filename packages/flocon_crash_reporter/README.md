# flocon_crash_reporter

Sends the uncaught Dart and Flutter errors of your app, with their stack trace, to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger. The handlers already set (Crashlytics, Sentry...) keep working.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_crash_reporter:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_crash_reporter
```

## Usage

```dart
import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';

await startFlocon((flocon) => flocon..install(FloconCrashReporter()));
```

Errors are saved on disk and sent on the next connection, even after a restart. Native crashes are not reported.

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
