# FloconFlutter

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps
(see also [FloconSwift](https://github.com/openflocon/FloconSwift)).

Once the SDK is started, your app connects to the Flocon desktop app and shows, live:

| Feature | How |
| --- | --- |
| **Network** (HTTP) | [`dio.withFlocon()`](#dio) for [Dio](https://pub.dev/packages/dio), [`client.withFlocon()`](#packagehttp) for [`package:http`](https://pub.dev/packages/http). Headers, bodies, timing, errors, images. Separate packages, so you only pull the HTTP library you use |
| **Network mocks** and **bad network** | configured from the desktop, applied by the Dio and `http` adapters, nothing to code (see [Mocks](#mocks-and-bad-network)) |
| **Network** (WebSocket) | [`floconLogWebSocketEvent`](#websockets): log the events of the connections you want to inspect |
| **Analytics** | [`floconAnalytics(stream)`](#analytics): one table per stream (e.g. per provider) |
| **Feature flags** | [`floconFeatureFlags(provider)`](#feature-flags): the flags your app evaluated, with their variant and payload |
| **Timeline** | [`floconTimeline`](#timeline): navigation, user actions, lifecycle and your own events |
| **Deeplinks** | [`floconRegisterDeeplinks`](#deeplinks): the deeplinks of your app, with their parameters |
| **Databases** | [`install(FloconDatabase())`](#databases): query the SQLite databases of your app, and see the queries it runs |
| **Dashboard** | [`floconDashboard`](#dashboard): values of your app updated live, and buttons, inputs and forms that run actions in it |
| **Tables** | [`floconTable(name)`](#tables): any structured data you want to inspect while the app runs |
| **Preferences** | [`install(FloconSharedPreferences(prefs))`](#preferences): browse and edit your `SharedPreferences` from the desktop |
| **App icon** | your app shows with its icon in the desktop, nothing to set up |
| **Files** | [`install(FloconFiles())`](#files): browse, download and delete the files of your app from the desktop |
| **Crash reporter** | [`install(FloconCrashReporter())`](#crash-reporter): uncaught Dart and Flutter errors, with their stack trace |

## Packages

The SDK is split in several packages, so that you only depend on the libraries you actually use:

| Package | Content | Depends on |
| --- | --- | --- |
| `flocon` | connection, app icon (native code for Android, iOS and macOS), Network (WebSocket events, mocks), Analytics, Tables, custom plugins | `path_provider`, no HTTP library |
| `flocon_dio` | `dio.withFlocon()` (`FloconDioInterceptor`) | `dio` |
| `flocon_http` | `client.withFlocon()` (`FloconHttpClient`) | `http` |
| `flocon_shared_preferences` | Preferences plugin | `shared_preferences` |
| `flocon_files` | Files plugin | `path_provider` |
| `flocon_crash_reporter` | Crash reporter plugin | `path_provider` |
| `flocon_database` | Database plugin (SQLite) | `sqflite` |
| `flocon_qr_scanner` | `FloconQrScannerView`: connect by scanning the QR code of the desktop (Android, iOS, macOS) | `mobile_scanner` |

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
  flocon_files:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_files
  flocon_crash_reporter:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_crash_reporter
  flocon_database:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_database
  flocon_qr_scanner:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_qr_scanner
```

## Getting started

Start the SDK as early as possible with `startFlocon`, and `install` the plugins you use, with their options
(like `startFlocon { install(...) }` of the Android SDK):

```dart
import 'package:flocon/flocon.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debug builds only: connects in the background, retries every 3s, keeps what is logged meanwhile
  if (kDebugMode) await initializeFlocon();
  runApp(const MyApp());
}

Future<void> initializeFlocon() async {
  final prefs = await SharedPreferences.getInstance();
  await startFlocon((flocon) => flocon
    ..connect(host: Platform.isAndroid ? '10.0.2.2' : 'localhost')
    ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'images.example.com'))
    ..install(FloconFiles())
    ..install(FloconDatabase())
    ..install(FloconCrashReporter())
    ..install(FloconSharedPreferences(prefs)));
}
```

| Plugin | Package | Section |
| --- | --- | --- |
| `FloconNetwork` | `flocon` | [Network](#network) |
| `FloconFiles` | `flocon_files` | [Files](#files) |
| `FloconDatabase` | `flocon_database` | [Databases](#databases) |
| `FloconCrashReporter` | `flocon_crash_reporter` | [Crash reporter](#crash-reporter) |
| `FloconSharedPreferences` | `flocon_shared_preferences` | [Preferences](#preferences) |

The plugins of the `flocon` package (network, analytics, tables, timeline, feature flags, deeplinks, dashboard) are always
available: install `FloconNetwork` only to give it options. Calling `startFlocon` more than once has no effect, and every
Flocon call is a no-op before it.

### Debug builds only

Flocon is a debugging tool: **do not start it in release builds**. Once connected, the desktop app can read your
network calls, edit your preferences, delete files and run SQL on your databases, and the connection accepts the
self-signed certificate of the desktop without verifying it.

The `kDebugMode` check above is the only guard you need: every other Flocon call (`floconAnalytics`, `floconTimeline`,
`withFlocon()`...) does nothing when Flocon was not started, so you can leave them in your code.
`kDebugMode` is a constant, so the call is removed from release builds by the compiler. Use `!kReleaseMode` instead to also
keep it in profile builds.

The packages stay in your `dependencies` (a `dev_dependency` cannot be imported from `lib/`), so their native code and
their dependencies (`device_info_plus`, `sqflite`, `mobile_scanner`...) are still in the release binary. To keep the
Flocon Dart code out of it too, start Flocon from a debug-only entry point, and do all your Flocon setup there (no Flocon
import in the rest of `lib/`):

```dart
// lib/main_debug.dart
import 'package:flocon/flocon.dart';
import 'package:flutter/widgets.dart';
import 'main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startFlocon((flocon) => flocon..install(FloconNetwork()));
  app.main();
}
```

```bash
flutter run -t lib/main_debug.dart   # debug, with Flocon
flutter build apk                    # release, from lib/main.dart, without Flocon
```

### Host

| Where the app runs | Host |
| --- | --- |
| iOS Simulator, macOS | `localhost` (default) |
| Android emulator | `10.0.2.2` |
| Physical device | the local IP address of the computer running Flocon |

```dart
await startFlocon((flocon) => flocon..connect(host: '192.168.1.20'));
```

### Custom ports

The SDK uses the ports `9023` (WebSocket) and `9024` (HTTP) of the desktop app. If you changed them in the Flocon desktop
settings, give the same values (a port outside 1...65535 is replaced by the default one):

```dart
await startFlocon((flocon) => flocon..connect(host: '192.168.1.20', webSocketPort: 9100, httpPort: 9101));
```

### Connecting to another address

By default the SDK tries the host given to `connect` and keeps retrying every 3 seconds. If the address of the computer is not known when
the app starts (the user types it in, scans a QR code...), call `Flocon.connect` when you have it. The SDK keeps trying
`localhost` and also connects to this address:

```dart
final result = await Flocon.connect('192.168.1.20'); // or '192.168.1.20:10023' or '192.168.1.20:10023:10024'
```

`host`, `host:wsPort` or `host:wsPort:httpPort`: an omitted port is the configured one, and a scheme, a path or an
invalid port gives `FloconConnectResultInvalidAddress`. It returns a `FloconConnectResult` (connected, not started, invalid
address, failed) instead of throwing; what the app logs is kept in every case, so you can call it again. The desktop shows a
wifi icon next to a device connected this way. The last address is tried again at the next launch
(`FloconConfig.rememberLastAddress`). `await Flocon.disconnect()` closes it and forgets it.

Until a desktop is reachable, everything the app logs is kept in memory (up to `FloconConfig.bufferCapacity`, 5000 messages:
above it the oldest are dropped), and sent in order once connected. The same buffer is used when the connection is lost.

Follow the connection with `Flocon.connectionState` or the `Flocon.connectionStates` stream (idle, buffering, connecting,
connected, failed):

```dart
Flocon.connectionStates.listen((state) => switch (state) {
      FloconConnected() => print('connected'),
      FloconFailed(:final reason) => print('failed: $reason'),
      _ => null,
    });
```

#### Scanning a QR code

`flocon_qr_scanner` scans the QR code of Flocon Desktop (the IP address of the computer, with both ports when they are not
the defaults) and connects with `Flocon.connect`:

```dart
FloconQrScannerView(onResult: (result) {
  if (result is FloconConnectResultConnected) Navigator.pop(context);
})
```

Camera permission: `NSCameraUsageDescription` (iOS, macOS), the `CAMERA` permission (Android),
`com.apple.security.device.camera` in the macOS entitlements. On Android the camera libraries of `mobile_scanner` need `minSdk` 23,
`compileSdk` 36 and the Android Gradle plugin 8.9.1 or higher (see `sample/android`).

### Console logs

The SDK prints nothing by default. To see what it does, for example when the app does not show up in the desktop app:

```dart
Flocon.isLoggingEnabled = true;
await startFlocon((flocon) => flocon..install(FloconNetwork()));
```

### Platform setup

The connection uses `wss://` with the self-signed certificate of the desktop app, which is accepted without being verified
(the connection is encrypted, not authenticated), so no cleartext traffic nor App Transport Security exception is needed
(neither for the HTTPS downloads of the Files plugin).

- **Android**: the `INTERNET` permission.
- **iOS**: `NSLocalNetworkUsageDescription`, to reach the computer on the local network.
- **macOS**: the `com.apple.security.network.client` entitlement.

See `sample/` for a working configuration of the three platforms.

## Network

### Dio

`import 'package:flocon_dio/flocon_dio.dart';`

```dart
final dio = Dio(BaseOptions(baseUrl: baseUrl)).withFlocon();
```

`withFlocon()` adds the `FloconDioInterceptor`: call it after adding your own interceptors, so it sees the final request
and the raw response.

### package:http

`import 'package:flocon_http/flocon_http.dart';`

```dart
final client = http.Client().withFlocon(); // a FloconHttpClient wrapping it
final response = await client.get(Uri.parse('https://example.com'));
```

The response body is read in full to be logged, then returned unchanged: avoid it for very long streams.

### Options

The options of `FloconNetwork`, given at start, apply to the calls of every client (Dio and `package:http`): which calls are
sent, and which responses are images (their body is not sent, the desktop downloads them from their URL). Responses with a
`Content-Type: image/*` header are always treated as images.

```dart
await startFlocon((flocon) => flocon
  ..install(FloconNetwork(
    shouldLog: (request) => request.url.host != 'analytics.example.com',
    isImage: (request, response) => request.url.path.startsWith('/images/'),
  )));
```

`request` is a `FloconHttpRequest` (`url`, `method`, `headers`) and `response` a `FloconHttpResponse` (`statusCode`,
`headers`, `contentType`), whatever the HTTP library.

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

Mocks and the configuration are saved on the device and apply from the next launch too, before the app connects to the desktop.
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

## Feature flags

Register the flags your app evaluated, one provider per feature flag system (Firebase Remote Config, Statsig, an in-house
one...). No dependency on their SDKs: each call replaces the flags of the provider, and they are sent again when the app
reconnects to the desktop:

```dart
floconFeatureFlags('firebase').register([
  FloconFeatureFlag(name: 'new_checkout', state: FloconFeatureFlagState.custom, variant: 'treatment', payload: '{"steps": 3}'),
  FloconFeatureFlag(name: 'dark_mode', state: FloconFeatureFlagState.on, variant: 'on'),
  FloconFeatureFlag(name: 'onboarding_v2', state: FloconFeatureFlagState.off, variant: 'control'),
]);
```

`state` (`on`, `off`, or `custom` for an experiment arm or a value) colors the variant in the desktop. The desktop lists
the flags with a search, and shows the payload (formatted when it is json) when you click a flag.

## Timeline

Log what happens in your app: the events appear in the Flocon timeline, with their time.

```dart
// typed events, without a level
floconTimeline.logNavigation('CheckoutScreen', params: {'from': 'CartScreen'});
floconTimeline.logUserAction('tap_buy', params: {'sku': 'premium_yearly'});
floconTimeline.logLifecycle('resumed');
floconTimeline.log(const TimelineType('billing'), 'Purchase started');

// tagged events, with a level: debug, info (default), warning or error
floconTimeline.logTagged('billing', 'Purchase failed', params: {'sku': 'premium_yearly'}, level: TimelineLevel.error);
```

`navigation`, `userAction` and `lifecycle` are shown with their own icon; any other type or tag is a custom one, listed in
the Type filter. A typed call has no level, a tagged call always has one. Params are text only.

Two observers log the navigation and the lifecycle for you:

```dart
MaterialApp(navigatorObservers: [FloconNavigatorObserver()], /* ... */);
FloconLifecycleObserver.start(); // resumed, inactive, paused, hidden, detached
```

A route is named by its `RouteSettings.name`, otherwise by its type: name your routes to read them in the timeline.

## Deeplinks

List the deeplinks of your app, writing the parts to fill in between brackets. The desktop opens them itself:

```dart
floconRegisterDeeplinks(
  [
    FloconDeeplink('myapp://home', label: 'Home'),
    FloconDeeplink(
      'myapp://user/[userId]',
      label: 'User',
      description: 'Open the profile of a user',
      parameters: [FloconDeeplinkParameter.autoComplete('userId', ['Florent', 'David'])],
    ),
    FloconDeeplink('myapp://[env]/settings', parameters: [FloconDeeplinkParameter.variable('env', variableName: 'env')]),
  ],
  variables: [FloconDeeplinkVariable('env', suggestions: ['staging', 'production'])],
);
```

A variable is shared by several deeplinks, and edited once in the desktop app.

## Databases

`import 'package:flocon_database/flocon_database.dart';`

```dart
await startFlocon((flocon) => flocon..install(FloconDatabase()));
```

The SQLite files of the databases folder (`sqflite`), the documents folder (Android, iOS, macOS sandbox) and the application
support folder are shown without any setup, **whatever their extension** (Drift, sqflite, plain SQLite files...). Run any
SQL query on them from the desktop. Queries run on their own connection, next to the one of the app. Blobs are shown as
hexadecimal, truncated after 64 bytes. Only the listed databases can be queried.

Register the databases stored elsewhere, or give one a clearer name:

```dart
floconRegisterDatabase('Shared', '/path/to/shared.sqlite');
```

To see the queries run by the app, log them from the hook of your database library. A query is linked to its database by
the path of its file. For example with Drift:

```dart
class FloconQueryInterceptor extends QueryInterceptor {
  FloconQueryInterceptor(this.path);
  final String path;

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor e, String statement, List<Object?> args) {
    floconLogDatabaseQuery(path, statement, args);
    return super.runSelect(e, statement, args);
  }
  // same for runInsert, runUpdate, runDelete, runCustom
}
```

## Dashboard

A dashboard shows values of the app, and runs actions in it from the desktop app. A section is either static, or rebuilt
each time a `ValueListenable` (`FloconSection.listen`) or a `Stream` (`FloconSection.fromStream`) emits:

```dart
// keep the handle: the dashboard stops following the sections when you call handle.dispose()
final handle = floconDashboard('main', [
  FloconSection.listen('User', session.user, (user) => [
    FloconText('name', user.name),
    FloconText('status', user.status, color: 0xFFFF0000), // ARGB
    FloconButton('Log out', id: 'logout', onClick: session.logOut),
    FloconTextField(id: 'rename', label: 'Rename', value: user.name, onSubmitted: session.rename),
    FloconCheckBox(id: 'premium', label: 'Premium', value: user.isPremium, onChanged: session.setPremium),
  ]),
  FloconSection('Build', [
    FloconPlainText('commit', buildCommit),
    FloconJson('config', configJson),
    FloconMarkdown('Release note', '# 1.0\nFirst **release**'),
    FloconHtml('About', '<h1>MyApp</h1>'),
  ]),
  FloconForm('Create user', [
    FloconTextField(id: 'name', label: 'Name', value: ''),
    FloconCheckBox(id: 'admin', label: 'Admin', value: false),
  ], submitText: 'Create', onSubmitted: (values) => session.createUser(values['name'] ?? '', values['admin'] == 'true')),
]);
```

Element identifiers must be unique in their dashboard. A form sends the values of its inputs together, keyed by their
identifiers, with check boxes as `'true'` or `'false'`. The dashboard is sent once every reactive section has a value, and
again on each connection.

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
await startFlocon((flocon) => flocon..install(FloconSharedPreferences(prefs))); // optional name: the store in the desktop
```

The desktop lists the keys with their typed values and lets you edit `String`, `bool`, `int`, `double`
and `List<String>` values; an edit is only applied when its type matches the stored one. Any key can be deleted from the
desktop (right-click on a row, then Delete). The store is shown with its type (`SharedPreferences`).
Install it several times with different names, or register other instances later with
`floconRegisterSharedPreferences(prefs, name: 'Other')`.

## Files

`import 'package:flocon_files/flocon_files.dart';`

```dart
await startFlocon((flocon) => flocon..install(FloconFiles()));
```

The desktop shows, without anything to register, the `Documents`, `Application Support`, `Caches` and `tmp` folders and,
on Android and iOS, the whole data folder of the app (`App container`; on macOS only inside the sandbox). It can browse
them, download a file (uploaded to the desktop over HTTPS, port 9024, streamed) and delete files, folders or the content of
a folder.

Register other folders, such as an export folder, to show them next to the default ones:

```dart
floconRegisterFilesFolder('Exports', Directory('${docs.path}/exports'));
```

- Nothing outside of the root folders is reachable (`..` and symbolic links are resolved), and the root folders themselves
  are never deleted. A symbolic link is deleted, never followed.
- A folder registered at the location of a default one renames it.

## Crash reporter

`import 'package:flocon_crash_reporter/flocon_crash_reporter.dart';`

```dart
await startFlocon((flocon) => flocon..install(FloconCrashReporter()));
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

Flocon.register(MyPlugin()); // after startFlocon
```

To install it with `startFlocon` like the others, give it a factory:

```dart
class MyPluginFactory extends FloconPluginFactory {
  const MyPluginFactory();
  @override
  Future<void> install() async => Flocon.register(MyPlugin());
}

await startFlocon((flocon) => flocon..install(const MyPluginFactory()));
```

To send messages, get the sender with `Flocon.messageSender`; find a registered plugin with `Flocon.plugin<T>()`.

## Sample

`sample/` is a Flutter app (Android, iOS, macOS) that looks like the Flocon Desktop dark theme, and like the demos of the
Android and Swift SDKs: the home shows the four main plugins as tiles and the others as rows, a chip next to the title shows
the connection and opens the connection screen (address, QR code, disconnect), and **each plugin has its own screen**, made of
rows with a *Run* button that shows ✓ and the duration, or ✕ and the error.

| Screen | Content |
| --- | --- |
| **Network** | Dio and `package:http` calls (GET, POST, PUT, DELETE, image, slow, upload), errors (404, 500, unknown host), a WebSocket echo with the events logged by hand, and two calls to try the mocks and the bad network set from the desktop |
| **Database** | `dogs.sqlite` (sqflite) created and registered, rows inserted and queries logged |
| **Analytics** | your own event on any stream, and presets for Firebase- and Amplitude-style providers |
| **Feature flags** | Firebase and Statsig flags with variants and payloads, registered at start and shuffled on demand |
| **Preferences** | the `SharedPreferences` store, to edit and delete from the desktop |
| **Files** | text, JSON and big files in the documents, support and cache folders, and a registered `Exports` folder |
| **Dashboard & Tables** | a live user section, a form, buttons and inputs that run actions in the app, and table rows |
| **Deeplinks** | the links listed in the desktop, opened inside the sample |
| **Timeline** | typed, tagged and custom logs; the screen changes and the app lifecycle are logged automatically |
| **Images** | six images loaded through Dio or `package:http` and displayed in a grid |
| **Crash reporter** | errors thrown from a callback, a `Future` and `build()` |

Start the Flocon desktop app, then:

```bash
cd sample && flutter run -d macos
```

The sample picks `10.0.2.2` on Android and `localhost` elsewhere. On a physical device, use the connection screen (type the IP
of the computer, or scan its QR code). The camera permissions of the QR scanner are declared for the three platforms
(Android `minSdk` 23 / `compileSdk` 36 / AGP 8.9.1, `NSCameraUsageDescription`, the macOS camera entitlement).

## Development

```bash
tool/check.sh   # pub get, analyze and test in every package and in the sample
```

```
packages/
  flocon/                       # core
    lib/src/                    #   flocon.dart, config.dart, client/ (WebSocket, queue, envelope),
                                #   core/, model/, plugins/network|analytics|table
  flocon_dio/                   # Dio interceptor, Dio.withFlocon()
  flocon_http/                  # package:http client wrapper, Client.withFlocon()
  flocon_shared_preferences/    # Preferences plugin
  flocon_files/                 # Files plugin
  flocon_crash_reporter/        # Crash reporter plugin
  flocon_database/              # Database plugin
  flocon_qr_scanner/            # QR code scanner view
sample/                         # sample app, one screen per plugin
tool/check.sh
```

The adapter packages only depend on the public API of `flocon` (`Flocon.networkPlugin`, `Flocon.messageSender`,
`Flocon.register`, `FloconPlugin`).

The protocol is the one of [FloconSwift](https://github.com/openflocon/FloconSwift): a WebSocket on port 9023,
each message wrapped in an envelope (`deviceId`, `plugin`, `method`, `body`, `appName`, `appPackageName`,
`deviceName`, `appInstance`, `platform`, `versionName`).

## Status / TODO

Not implemented yet: mocks of WebSocket messages, and the other device features (restart app).
