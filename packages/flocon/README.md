# flocon

Core of the Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps: connection to the desktop app, Network (WebSocket events, mocks, bad network), Analytics, Feature flags, Timeline, Deeplinks, Dashboard, Tables and custom plugins.

## Installation

```bash
flutter pub add flocon
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^LAST_VERSION
```

## Usage

```dart
import 'package:flocon/flocon.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await startFlocon((flocon) => flocon
      ..connect(host: 'localhost') // 10.0.2.2 from the Android emulator
      ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'images.example.com')));
  }
  runApp(const MyApp());
}

Flocon.analytics.sender('firebase').logEvents([
  AnalyticsEvent(eventName: 'button_clicked', properties: [AnalyticsProperty('button_id', 'pay')]),
]);
Flocon.timeline.logUserAction('tap_buy');
```

HTTP calls are captured by [`flocon_dio`](https://pub.dev/packages/flocon_dio) or
[`flocon_http`](https://pub.dev/packages/flocon_http).

See the [documentation](https://openflocon.github.io/Flocon/setup/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
