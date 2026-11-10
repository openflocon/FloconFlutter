# flocon_shared_preferences

Browse and edit your [`SharedPreferences`](https://pub.dev/packages/shared_preferences) from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger.

## Installation

There is no release on pub.dev yet, depend on the repository:

```yaml
dependencies:
  flocon:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon
  flocon_shared_preferences:
    git:
      url: https://github.com/openflocon/FloconFlutter.git
      path: packages/flocon_shared_preferences
```

## Usage

```dart
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';

Flocon.initialize();
floconRegisterSharedPreferences(await SharedPreferences.getInstance());
```

See the [full documentation](https://github.com/openflocon/FloconFlutter#readme) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
