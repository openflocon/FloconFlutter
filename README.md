# FloconFlutter

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps
(see also [FloconSwift](https://github.com/openflocon/FloconSwift)).

Once the SDK is started, your app connects to the Flocon desktop app and shows, live:

| Feature | How |
| --- | --- |
| **Network** (HTTP) | [`FloconDioInterceptor`](#dio) for [Dio](https://pub.dev/packages/dio), [`FloconHttpClient`](#packagehttp) for [`package:http`](https://pub.dev/packages/http). Headers, bodies, timing, errors, images. Separate packages, so you only pull the HTTP library you use |
| **Network** (WebSocket) | [`floconLogWebSocketEvent`](#websockets): log the events of the connections you want to inspect |
| **Analytics** | [`floconAnalytics(stream)`](#analytics): one table per stream (e.g. per provider) |
| **Tables** | [`floconTable(name)`](#tables): any structured data you want to inspect while the app runs |
| **Preferences** | [`floconRegisterSharedPreferences`](#preferences): browse and edit your `SharedPreferences` from the desktop |

## Packages

The SDK is split in several packages, so that you only depend on the libraries you actually use:

| Package | Content | Depends on |
| --- | --- | --- |
| `flocon` | connection, Network (WebSocket events), Analytics, Tables, custom plugins | no HTTP library |
| `flocon_dio` | `FloconDioInterceptor` | `dio` |
| `flocon_http` | `FloconHttpClient` | `http` |
| `flocon_shared_preferences` | Preferences plugin | `shared_preferences` |

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  # only the ones you need:
  flocon_dio:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_dio
  flocon_http:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_http
  flocon_shared_preferences:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_shared_preferences
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

`import 'package:flocon_dio/flocon_dio.dart';`

```dart
final dio = Dio()..interceptors.add(FloconDioInterceptor());
```

Add it last, so it sees the final request and the raw response.

### package:http

`import 'package:flocon_http/flocon_http.dart';`

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

## Preferences

`import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';`

```dart
final prefs = await SharedPreferences.getInstance();
floconRegisterSharedPreferences(prefs); // optional second argument: the name of the store in the desktop
```

The desktop lists the keys with their typed values and lets you edit `String`, `bool`, `int`, `double`
and `List<String>` values; an edit is only applied when its type matches the stored one.
Call it after `Flocon.initialize()` (it does nothing before). Register several instances with different names.

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

To send messages, get the sender with `Flocon.messageSender`; find a registered plugin with `Flocon.plugin<T>()`.

```dart
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
| **Preferences** | a `SharedPreferences` store with a String, bool, int, double and string list, editable from Flocon |

Start the Flocon desktop app, then:

```bash
cd sample && flutter run -d macos
```

The sample picks `10.0.2.2` on Android and `localhost` elsewhere (edit `sample/lib/main.dart` for a physical device).

## Development

```bash
tool/check.sh   # pub get, analyze and test in every package and in the sample
```

```
packages/
  flocon/                       # core
    lib/src/                    #   flocon.dart, config.dart, client/ (WebSocket, queue, envelope),
                                #   core/, model/, plugins/network|analytics|table
  flocon_dio/                   # Dio interceptor + FloconNetworkOptions
  flocon_http/                  # package:http client wrapper
  flocon_shared_preferences/    # Preferences plugin
sample/                         # sample app
tool/check.sh
```

The adapter packages only depend on the public API of `flocon` (`Flocon.networkPlugin`, `Flocon.messageSender`,
`Flocon.register`, `FloconPlugin`).

The protocol is the one of [FloconSwift](https://github.com/openflocon/FloconSwift): a WebSocket on port 9023,
each message wrapped in an envelope (`deviceId`, `plugin`, `method`, `body`, `appName`, `appPackageName`,
`deviceName`, `appInstance`, `platform`, `versionName`).

## Status / TODO

Not implemented yet (they are not in FloconSwift's network plugin either): network mocks and bad-network
simulation configured from the desktop, files, device plugins.
