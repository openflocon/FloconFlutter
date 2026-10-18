# FloconFlutter

Flutter SDK for [Flocon](https://github.com/openflocon/Flocon), the desktop debugging tool for mobile apps
(see also [FloconSwift](https://github.com/openflocon/FloconSwift)).

Current scope: **Network** (HTTP through [Dio](https://pub.dev/packages/dio), plus manual WebSocket events).

## Usage

```dart
import 'package:flocon/flocon.dart';

void main() {
  Flocon.initialize(); // connects in the background, retries every 3s, queues messages meanwhile
  runApp(const MyApp());
}

final dio = Dio()..interceptors.add(FloconDioInterceptor());
```

Host to use: `localhost` (iOS Simulator, macOS), `10.0.2.2` (Android emulator), the Mac's LAN IP (physical device):

```dart
Flocon.initialize(config: FloconConfig(host: '192.168.1.20'));
```

Platform setup: Android needs `INTERNET` + `usesCleartextTraffic` (plain `ws://`); iOS needs
`NSLocalNetworkUsageDescription` and an ATS exception; macOS needs the `network.client` entitlement
(see `sample/`).

### Options

```dart
FloconDioInterceptor(
  networkOptions: FloconNetworkOptions(
    shouldLog: (request) => request.uri.host != 'analytics.example.com',
    isImage: (request, response) => request.uri.path.startsWith('/images/'),
  ),
);
```

### WebSockets

```dart
floconLogWebSocketEvent(FloconWebSocketEvent(
  websocketUrl: url, event: FloconWebSocketEventType.sendMessage, message: text));
```

## Sample

`sample/` is a Flutter app (iOS, Android, macOS) with buttons for GET/POST/PUT/DELETE, 404, 500, network error,
slow request, image, FormData and a WebSocket demo.

```bash
cd sample && flutter run -d macos
```

## Status / TODO
Network mocks, bad-network simulation, analytics, tables, preferences, files, device plugins (not in FloconSwift's network plugin either yet).
