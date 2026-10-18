# FloconFlutter

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps
(see also [FloconSwift](https://github.com/openflocon/FloconSwift)).

Once the SDK is started, your app connects to the Flocon desktop app and shows, live:

| Feature | How |
| --- | --- |
| **Network** (HTTP) | [`FloconDioInterceptor`](#dio) for [Dio](https://pub.dev/packages/dio), [`FloconHttpClient`](#packagehttp) for [`package:http`](https://pub.dev/packages/http). Headers, bodies, timing, errors, images |
| **Network** (WebSocket) | [`floconLogWebSocketEvent`](#websockets): log the events of the connections you want to inspect |
| **Analytics** | [`floconAnalytics(stream)`](#analytics): one table per stream (e.g. per provider) |
| **Tables** | [`floconTable(name)`](#tables): any structured data you want to inspect while the app runs |

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git: https://github.com/openflocon/FloconFlutter.git
  dio: ^5.0.0   # if you use Dio
  http: ^1.0.0  # if you use package:http
```

## Getting started

Start the SDK as early as possible:

```dart
import 'package:flocon/flocon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flocon.initialize(); // connects in the background, retries every 3s, queues messages meanwhile
  runApp(const MyApp());
}
```

Calling `initialize` more than once has no effect, and every Flocon call is a no-op before it.
You will probably want to enable it in debug builds only (`if (kDebugMode) Flocon.initialize();`).

### Host

| Where the app runs | Host |
| --- | --- |
| iOS Simulator, macOS | `localhost` (default) |
| Android emulator | `10.0.2.2` |
| Physical device | the local IP address of the computer running Flocon |

```dart
Flocon.initialize(config: FloconConfig(host: '192.168.1.20'));
```

### Platform setup

The connection uses plain `ws://`:

- **Android**: `INTERNET` permission and `android:usesCleartextTraffic="true"`.
- **iOS**: `NSLocalNetworkUsageDescription` and an App Transport Security exception (`NSAllowsLocalNetworking`).
- **macOS**: the `com.apple.security.network.client` entitlement.

See `sample/` for a working configuration of the three platforms.

## Network

### Dio

```dart
final dio = Dio()..interceptors.add(FloconDioInterceptor());
```

Add it last, so it sees the final request and the raw response.

### package:http

```dart
final client = FloconHttpClient(http.Client());
final response = await client.get(Uri.parse('https://example.com'));
```

The response body is read in full to be logged, then returned unchanged: avoid it for very long streams.

### Options

Both accept the same options, to choose which requests are sent and which responses are images
(their body is not sent, the desktop downloads them from their URL). Responses with a
`Content-Type: image/*` header are always treated as images.

```dart
// Dio
FloconDioInterceptor(
  networkOptions: FloconNetworkOptions(
    shouldLog: (request) => request.uri.host != 'analytics.example.com',
    isImage: (request, response) => request.uri.path.startsWith('/images/'),
  ),
);

// package:http
FloconHttpClient(
  http.Client(),
  shouldLog: (request) => request.url.host != 'analytics.example.com',
  isImage: (request, response) => request.url.path.startsWith('/images/'),
);
```

### WebSockets

WebSocket traffic cannot be intercepted automatically: log the events of the connections you want to inspect.

```dart
floconLogWebSocketEvent(FloconWebSocketEvent(
  websocketUrl: url,
  event: FloconWebSocketEventType.sendMessage, // open, closing, closed, error, sendMessage, receiveMessage
  message: text,
));
```

## Analytics

Each stream is shown as its own table in the desktop app. Use one stream per analytics provider,
to check what each of them receives.

```dart
floconAnalytics('firebase').logEvents([
  AnalyticsEvent(
    eventName: 'button_clicked',
    properties: [AnalyticsProperty('button_id', 'checkout_pay')],
  ),
]);
```

## Tables

Columns are created from the names used in the logged rows.

```dart
floconTable('users').log([
  TableColumnConfig('name', 'Florent'),
  TableColumnConfig('age', '33'),
]);
```

## Custom plugins

```dart
class MyPlugin implements FloconPlugin {
  @override
  String get pluginName => 'my-plugin';
  @override
  void onConnectedToServer() {}
  @override
  void onMessageReceived(FloconMessageFromServer message) {}
}

Flocon.register(MyPlugin()); // after Flocon.initialize()
```

## Sample

`sample/` is a Flutter app (iOS, Android, macOS). Its home screen links to one screen per feature:

| Screen | Content |
| --- | --- |
| **Dio** | GET (with query), POST, PUT, DELETE, 404, 500, network error, slow request, `FormData` upload |
| **package:http** | the same calls, with a multipart upload |
| **Images** | six images downloaded through Dio or `package:http` (switchable) and displayed in a grid |
| **WebSocket** | open, send and close an echo connection, with each event logged |
| **Analytics** | events on two streams (`firebase`, `amplitude`) and a batch of events |
| **Tables** | rows added to the `users` and `settings` tables |

Start the Flocon desktop app, then:

```bash
cd sample && flutter run -d macos
```

The sample picks `10.0.2.2` on Android and `localhost` elsewhere (edit `sample/lib/main.dart` for a physical device).

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

```
lib/src/
  flocon.dart, config.dart            # entry point, FloconConfig
  client/                             # WebSocket connection, message queue, envelope, plugin routing
  core/, model/                       # plugin interfaces, app infos, message types
  plugins/network/                    # network plugin, Dio interceptor, http client, WebSocket events
  plugins/analytics/, plugins/table/
test/                                 # JSON payload and interceptor tests
sample/                               # sample app
```

The protocol is the one of [FloconSwift](https://github.com/openflocon/FloconSwift): a WebSocket on port 9023,
each message wrapped in an envelope (`deviceId`, `plugin`, `method`, `body`, `appName`, `appPackageName`,
`deviceName`, `appInstance`, `platform`, `versionName`).

## Status / TODO

Not implemented yet (they are not in FloconSwift's network plugin either): network mocks and bad-network
simulation configured from the desktop, preferences, files, device plugins.
