<p align="center">
  <img height="450" alt="Flocon banner" src="https://raw.githubusercontent.com/openflocon/Flocon/main/ressources/flocon_banner_small.jpeg" />
</p>

# FloconFlutter

[![pub package](https://img.shields.io/pub/v/flocon.svg)](https://pub.dev/packages/flocon)
[![AI agents: MCP](https://img.shields.io/badge/AI%20agents-MCP-black)](https://openflocon.github.io/Flocon/mcp/)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugger for mobile apps. Once the SDK is
started, your app connects to the Flocon desktop app and shows, live: network calls, databases, preferences, files,
analytics, feature flags, timeline, crashes and more. Also available for Kotlin and Swift
([FloconSwift](https://github.com/openflocon/FloconSwift)).

| **Network**: every call, mocks, bad network | **Databases**: query your SQLite live |
|:---:|:---:|
| ![Network inspector](https://raw.githubusercontent.com/openflocon/Flocon/main/docs/assets/screenshots/network-detail.jpg) | ![Database](https://raw.githubusercontent.com/openflocon/Flocon/main/docs/assets/screenshots/database-sql-editor.jpg) |
| **Preferences**: browse and edit `SharedPreferences` | **Timeline**: what happened before the crash |
| ![Preferences](https://raw.githubusercontent.com/openflocon/Flocon/main/docs/assets/screenshots/preferences-list.jpg) | ![Timeline](https://raw.githubusercontent.com/openflocon/Flocon/main/docs/assets/screenshots/home-timeline-graph.jpg) |

Full documentation: **https://openflocon.github.io/Flocon/** (every feature page has a Flutter tab).

## Your AI agent can see your app

![An AI agent finds a failing checkout call through the Flocon MCP server and opens it in the Flocon timeline](https://raw.githubusercontent.com/openflocon/Flocon/main/docs/assets/screenshots/mcp-session.jpg)

Flocon Desktop runs an MCP server: Claude Code, Codex, Cursor or Gemini read the network calls, timeline, databases and preferences of your running Flutter app, then mock calls, simulate a bad network and take screenshots. Try asking:

- *"What happened right before the crash?"*
- *"Mock `/profile` with a 503 and take a screenshot."*
- *"Which analytics events are sent on checkout?"*

In Claude Code: `/plugin marketplace add openflocon/Flocon`, then `/plugin install flocon@flocon`. Other agents: [MCP setup](https://openflocon.github.io/Flocon/mcp/), and the [cookbook](https://openflocon.github.io/Flocon/mcp-cookbook/).

## Packages

The SDK is split in several packages, so that you only pull the libraries you use. All are published on pub.dev, and all but `flocon` depend on it.

| Package | What it adds | Main dependencies |
| --- | --- | --- |
| [`flocon`](https://pub.dev/packages/flocon) | Connection, app icon, network (WebSocket events, mocks, bad network), analytics, feature flags, timeline, deeplinks, dashboard, tables, custom plugins | `device_info_plus`, `package_info_plus`, `path_provider`, `uuid` |
| [`flocon_dio`](https://pub.dev/packages/flocon_dio) | `dio.withFlocon()`: network calls of [Dio](https://pub.dev/packages/dio) | `dio` |
| [`flocon_http`](https://pub.dev/packages/flocon_http) | `client.withFlocon()`: network calls of [`package:http`](https://pub.dev/packages/http) | `http` |
| [`flocon_database`](https://pub.dev/packages/flocon_database) | SQLite databases: browse, query, see the queries the app runs | `sqflite` |
| [`flocon_shared_preferences`](https://pub.dev/packages/flocon_shared_preferences) | Browse and edit `SharedPreferences` | `shared_preferences` |
| [`flocon_files`](https://pub.dev/packages/flocon_files) | Browse, download and delete the files of the app | `path_provider` |
| [`flocon_crash_reporter`](https://pub.dev/packages/flocon_crash_reporter) | Uncaught Dart and Flutter errors, with their stack trace | `path_provider` |
| [`flocon_qr_scanner`](https://pub.dev/packages/flocon_qr_scanner) | `FloconQrScannerView`: connect by scanning the QR code of the desktop (Android, iOS, macOS) | `mobile_scanner` |

## Install

```bash
flutter pub add flocon
# only the ones you need:
flutter pub add flocon_dio flocon_http flocon_database flocon_shared_preferences flocon_files flocon_crash_reporter flocon_qr_scanner
```

## Quick start

Start Flocon as early as possible, in debug builds only, and `install` the plugins you use:

```dart
import 'dart:io';

import 'package:flocon/flocon.dart';
import 'package:flocon_dio/flocon_dio.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await startFlocon((flocon) => flocon
      ..connect(host: Platform.isAndroid ? '10.0.2.2' : 'localhost')
      ..install(FloconNetwork()));
  }
  runApp(const MyApp());
}

final dio = Dio(BaseOptions(baseUrl: baseUrl)).withFlocon(); // after your own interceptors
```

Flocon is a debugging tool: the desktop can read your network calls, edit your preferences, delete files and run SQL on
your databases, so **do not start it in release builds**. Every other Flocon call (`withFlocon()`,
`Flocon.analytics`...) does nothing when Flocon was not started, so you can leave them in your code.

Other plugins are installed the same way: `FloconDatabase()`, `FloconSharedPreferences(prefs)`, `FloconFiles()`,
`FloconCrashReporter()`.

**Host.** `localhost` on the iOS Simulator and macOS, `10.0.2.2` on the Android emulator, and the local IP address of the
computer running Flocon on a physical device. If the address is not known at start, call `Flocon.connect('192.168.1.20')`
later, or scan the QR code of the desktop:

```dart
FloconQrScannerView(onResult: (result) {
  if (result is FloconConnectResultConnected) Navigator.pop(context);
})
```

**Platform setup.** The connection is a `wss://` one, so no cleartext traffic exception is needed.

- Android: the `INTERNET` permission.
- iOS: `NSLocalNetworkUsageDescription`, to reach the computer on the local network.
- macOS: the `com.apple.security.network.client` entitlement.
- QR scanner: `NSCameraUsageDescription` (iOS, macOS), the `CAMERA` permission (Android), `com.apple.security.device.camera`
  (macOS), and on Android `minSdk` 23, `compileSdk` 36, Android Gradle plugin 8.9.1+.

See [`sample/`](sample) for a working configuration of the three platforms, and
[Connect your app](https://openflocon.github.io/Flocon/setup/) for custom ports, connection state and troubleshooting.

## Features

| Feature | Flutter API | Documentation |
| --- | --- | --- |
| Network (HTTP) | `dio.withFlocon()`, `client.withFlocon()` | [Network](https://openflocon.github.io/Flocon/network/) |
| Mocks | set from the desktop, applied by the Dio and `http` adapters | [Mocking](https://openflocon.github.io/Flocon/mocking/) |
| Bad network | set from the desktop, applied by the Dio and `http` adapters | [Bad quality](https://openflocon.github.io/Flocon/bad-quality/) |
| WebSocket | `Flocon.network.logWebSocketEvent`, logged manually (no automatic capture) | [WebSocket](https://openflocon.github.io/Flocon/websocket/) |
| Images | responses with an `image/*` type, or `FloconNetwork(isImage: ...)` | [Image](https://openflocon.github.io/Flocon/image/) |
| Databases | `FloconDatabase()` (SQLite) | [Database](https://openflocon.github.io/Flocon/database/) |
| Preferences | `FloconSharedPreferences(prefs)` | [SharedPref](https://openflocon.github.io/Flocon/sharedpref/) |
| Files | `FloconFiles()` | [Files](https://openflocon.github.io/Flocon/files/) |
| Dashboard | `Flocon.dashboard` | [Dashboard](https://openflocon.github.io/Flocon/dashboard/) |
| Tables | `Flocon.table` | [Table](https://openflocon.github.io/Flocon/table/) |
| Deeplinks | `Flocon.deeplinks` | [Deeplink](https://openflocon.github.io/Flocon/deeplink/) |
| Analytics | `Flocon.analytics` | [Analytics](https://openflocon.github.io/Flocon/analytics/) |
| Feature flags | `Flocon.featureFlags` | [Feature flags](https://openflocon.github.io/Flocon/featureflags/) |
| Timeline | `Flocon.timeline`, `FloconNavigatorObserver`, `FloconLifecycleObserver` | [Timeline](https://openflocon.github.io/Flocon/timeline/) |
| Crash reporter | `FloconCrashReporter()` | [Crash reporter](https://openflocon.github.io/Flocon/crashreporter/) |

Flutter-specific limits:

- WebSocket traffic is not intercepted: log the events of the connections you want to inspect.
- Only Dart and Flutter errors are reported; native crashes (Kotlin, Java, Swift, C++) are not.
- Mocks of WebSocket messages are not supported.
- No WebView inspection and no accessibility tools.

## Sample

[`sample/`](sample) is a Flutter app (Android, iOS, macOS) with one screen per plugin, styled like the Flocon desktop.
Start the Flocon desktop app, then:

```bash
cd sample && flutter run -d macos
```

It picks `10.0.2.2` on Android and `localhost` elsewhere. On a physical device, use its connection screen (type the IP of
the computer, or scan the QR code).

## Development

```bash
tool/check.sh   # pub get, analyze and test in every package and in the sample
```

`packages/` holds the eight packages, one folder each (`flocon/lib/src` has the client, core, model and plugins); the
adapter packages only use the public API of `flocon`. The protocol is the one of
[FloconSwift](https://github.com/openflocon/FloconSwift).

## License

MIT, see [LICENSE](LICENSE).
