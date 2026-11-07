import 'package:flocon_sample/main.dart';
import 'package:flocon_sample/startup/sample_state.dart';
import 'package:flocon_sample/theme/sample_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> useSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('every screen builds without layout errors at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await useSize(tester, size);
      await tester.pumpWidget(const SampleApp());
      await tester.pumpAndSettle();
      expect(find.text('FLOCON SAMPLE'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final routes = [for (final s in SampleScreen.values) s.route, '/connection', '/user/Florent', '/post/2', '/settings/staging'];
      for (final route in routes) {
        SampleDeeplinks.navigatorKey.currentState!.pushNamed(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
        SampleDeeplinks.navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('the home lists the four main plugins as tiles and the others as rows', (tester) async {
    await useSize(tester, const Size(390, 1000));
    await tester.pumpWidget(const SampleApp());
    await tester.pumpAndSettle();
    for (final s in SampleScreen.main) {
      expect(find.text(s.title), findsOneWidget);
    }
    expect(find.text('MORE PLUGINS'), findsOneWidget);
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    expect(find.text('HTTP · DIO'), findsOneWidget);
  });

  testWidgets('an action row shows its result and duration', (tester) async {
    await useSize(tester, const Size(390, 1000));
    await tester.pumpWidget(const SampleApp());
    await tester.pumpAndSettle();
    SampleDeeplinks.navigatorKey.currentState!.pushNamed(SampleScreen.dashboard.route);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('✓ David'), findsOneWidget);
    expect(user.value.name, 'David');
  });

  test('the deeplinks of the sample open inside the app, others are refused', () {
    expect(SampleDeeplinks.open('https://example.com'), isFalse);
    expect(SampleDeeplinks.open('flocondemo://nowhere'), isFalse);
  });
}
