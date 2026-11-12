# flocon_dio

[Dio](https://pub.dev/packages/dio) interceptor that sends your HTTP calls to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger, and applies the mocks and the bad network set from the desktop.

## Installation

```bash
flutter pub add flocon flocon_dio
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^2.0.0
  flocon_dio: ^2.0.0
```

## Usage

```dart
import 'package:flocon_dio/flocon_dio.dart';

final dio = Dio(BaseOptions(baseUrl: baseUrl)).withFlocon(); // after your own interceptors
```

The options (which calls are sent, which responses are images) are given once, to the network plugin:

```dart
await startFlocon((flocon) => flocon
  ..install(FloconNetwork(isImage: (request, _) => request.url.host == 'images.example.com')));
```

See the [documentation](https://openflocon.github.io/Flocon/network/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
