# flocon_http

[`package:http`](https://pub.dev/packages/http) client wrapper that sends your HTTP calls to the [Flocon](https://github.com/openflocon/Flocon) desktop debugger, and applies the mocks and the bad network set from the desktop.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_http:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_http
```

## Usage

```dart
import 'package:flocon_http/flocon_http.dart';

final client = FloconHttpClient(http.Client());
final response = await client.get(Uri.parse('https://example.com'));
```

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
