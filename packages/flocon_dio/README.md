# flocon_dio

[Dio](https://pub.dev/packages/dio) interceptor that sends your HTTP calls to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger, and applies the mocks and the bad network set from the desktop.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_dio:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_dio
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

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
