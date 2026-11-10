# flocon

Core of the Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps: connection to the desktop app, Network (WebSocket events, mocks, bad network), Analytics, Feature flags, Timeline, Deeplinks, Dashboard, Tables and custom plugins.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
```

## Usage

```dart
import 'package:flocon/flocon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Flocon.initialize(); // localhost by default, 10.0.2.2 on the Android emulator
  runApp(const MyApp());
}

floconAnalytics('firebase').logEvents([
  AnalyticsEvent(eventName: 'button_clicked', properties: [AnalyticsProperty('button_id', 'pay')]),
]);
floconTimeline.logUserAction('tap_buy');
```

HTTP calls are captured by [`flocon_dio`](https://pub.dev/packages/flocon_dio) or
[`flocon_http`](https://pub.dev/packages/flocon_http).

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
