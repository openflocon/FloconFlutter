# FloconFlutter

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps
(see also [FloconSwift](https://github.com/openflocon/FloconSwift)).

Once the SDK is started, your app connects to the Flocon desktop app and shows, live:

| Feature | How |
| --- | --- |
| **Network** (HTTP) | [`FloconDioInterceptor`](#dio) for [Dio](https://pub.dev/packages/dio), [`FloconHttpClient`](#packagehttp) for [`package:http`](https://pub.dev/packages/http). Headers, bodies, timing, errors, images. Separate packages, so you only pull the HTTP library you use |
| **Network mocks** and **bad network** | configured from the desktop, applied by the Dio and `http` adapters, nothing to code (see [Mocks](#mocks-and-bad-network)) |
| **Network** (WebSocket) | [`floconLogWebSocketEvent`](#websockets): log the events of the connections you want to inspect |
| **Analytics** | [`floconAnalytics(stream)`](#analytics): one table per stream (e.g. per provider) |
| **Tables** | [`floconTable(name)`](#tables): any structured data you want to inspect while the app runs |
| **Preferences** | [`floconRegisterSharedPreferences`](#preferences): browse and edit your `SharedPreferences` from the desktop |
| **Device** | [`floconEnableDevicePlugin`](#device): your app shows with its icon in the desktop |
| **Crash reporter** | [`floconEnableCrashReporter`](#crash-reporter): uncaught Dart and Flutter errors, with their stack trace |

## Packages

The SDK is split in several packages, so that you only depend on the libraries you actually use:

| Package | Content | Depends on |
| --- | --- | --- |
| `flocon` | connection, Network (WebSocket events), Analytics, Tables, custom plugins | no HTTP library |
| `flocon_dio` | `FloconDioInterceptor` | `dio` |
| `flocon_http` | `FloconHttpClient` | `http` |
| `flocon_shared_preferences` | Preferences plugin | `shared_preferences` |
| `flocon_crash_reporter` | Crash reporter plugin | `path_provider` |
| `flocon_device` | Device plugin (app icon), has native code for Android, iOS and macOS | nothing else |

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
  flocon_crash_reporter:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_crash_reporter
  flocon_device:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_device
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

### Mocks and bad network

Both are configured from the Flocon desktop app, and applied by `FloconDioInterceptor` and `FloconHttpClient`:

- **Mocks** answer the calls whose URL (a regular expression that must match the whole URL) and method match,
  with the HTTP code, body, media type, headers and delay you set, or with an error. The first matching mock wins,
  and the call never reaches the network. Mocked calls are flagged in the desktop.
- **Bad network** adds random latency and makes random calls fail, with HTTP errors or exceptions, picked by weight.
  Mocks take precedence.

The exception names sent by the desktop are Java class names. They are mapped to what the library throws:
a name containing `Timeout` gives a timeout (`DioExceptionType.connectionTimeout` / `TimeoutException`),
the connection ones (`Socket`, `Connect`, `UnknownHost`, `SSL`) a connection error
(`DioExceptionType.connectionError` / `ClientException`), anything else an unknown error; the original name is the message.

Mocks and the configuration are kept in memory: the desktop sends them again at each connection.
Add the interceptor last, so the mock is not seen by interceptors added after it. Mocks of WebSocket messages are not supported.

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

## Device

`import 'package:flocon_device/flocon_device.dart';`

```dart
Flocon.initialize();
floconEnableDevicePlugin(); // answers the desktop's request for the app icon
```

The icon is read natively (Android: launcher icon, iOS: largest icon of the `Info.plist`, macOS: the app icon)
and sent as a base64 PNG of at most 300 pixels. Restarting the app from the desktop is not supported.

## Crash reporter

`import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';`

```dart
Flocon.initialize();
await floconEnableCrashReporter();
```

It hooks `FlutterError.onError` (build, layout, gestures...) and `PlatformDispatcher.instance.onError`
(uncaught asynchronous errors); the handlers already set (Crashlytics, Sentry...) keep working, they are called
after the report. Each error is saved on disk first, sent right away when the desktop is connected, and otherwise
sent on the next connection, even after a restart, then deleted.

Native crashes (Kotlin, Java, Swift, C++) are not reported.

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
| **Mocks and bad network** | a call you can mock or degrade from the desktop, shown with the result and its duration |
| **Images** | six images downloaded through Dio or `package:http` (switchable) and displayed in a grid |
| **WebSocket** | open, send and close an echo connection, with each event logged |
| **Analytics** | events on two streams (`firebase`, `amplitude`) and a batch of events |
| **Crash reporter** | throw an error from a tap, from a `Future` and from `build()` |
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
  flocon_crash_reporter/        # Crash reporter plugin
  flocon_device/                # Device plugin (app icon), with native code
sample/                         # sample app
tool/check.sh
```

The adapter packages only depend on the public API of `flocon` (`Flocon.networkPlugin`, `Flocon.messageSender`,
`Flocon.register`, `FloconPlugin`).

The protocol is the one of [FloconSwift](https://github.com/openflocon/FloconSwift): a WebSocket on port 9023,
each message wrapped in an envelope (`deviceId`, `plugin`, `method`, `body`, `appName`, `appPackageName`,
`deviceName`, `appInstance`, `platform`, `versionName`).

## Status / TODO

Not implemented yet: files, database, dashboard, deeplinks, mocks of WebSocket messages, and the other device features (restart app).
