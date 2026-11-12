# flocon_shared_preferences

Browse and edit your [`SharedPreferences`](https://pub.dev/packages/shared_preferences) from the [Flocon](https://github.com/openflocon/Flocon) desktop debugger.

## Installation

```bash
flutter pub add flocon flocon_shared_preferences
```

or in `pubspec.yaml`:

```yaml
dependencies:
  flocon: ^2.0.0
  flocon_shared_preferences: ^2.0.0
```

## Usage

```dart
import 'package:flocon_shared_preferences/flocon_shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();
await startFlocon((flocon) => flocon..install(FloconSharedPreferences(prefs)));
```

See the [documentation](https://openflocon.github.io/Flocon/sharedpref/) and the [`example`](example/main.dart).

## License

MIT, see [LICENSE](LICENSE).
