import 'dart:math';

import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user of the sample, shown live in the dashboard.
class SampleUser {
  const SampleUser({required this.name, required this.status, required this.isPremium});

  final String name;
  final String status;
  final bool isPremium;

  SampleUser copyWith({String? name, String? status, bool? isPremium}) => SampleUser(
        name: name ?? this.name,
        status: status ?? this.status,
        isPremium: isPremium ?? this.isPremium,
      );
}

final user = ValueNotifier(const SampleUser(name: 'Florent', status: 'active', isPremium: false));

/// Everything the sample registers when it starts: the plugins that list things, not log them.
class SampleStartup {
  static FloconDashboardHandle? _dashboard;

  static Future<void> run() async {
    registerFeatureFlags();
    registerDeeplinks();
    startDashboard();
    await seedPreferences();
  }

  static void registerFeatureFlags({bool shuffled = false}) {
    final random = Random();
    String pick(List<String> variants) => shuffled ? variants[random.nextInt(variants.length)] : variants.first;
    FloconFeatureFlag flag(String name, List<String> variants, {String? payload}) {
      final variant = pick(variants);
      return FloconFeatureFlag(
        name: name,
        state: switch (variant) {
          'on' => FloconFeatureFlagState.on,
          'off' || 'control' => FloconFeatureFlagState.off,
          _ => FloconFeatureFlagState.custom,
        },
        variant: variant,
        payload: variant == 'treatment' ? payload : null,
      );
    }

    floconFeatureFlags('firebase').register([
      flag('new_checkout', ['treatment', 'control'], payload: '{"steps": 3, "color": "red"}'),
      flag('dark_mode', ['on', 'off']),
      flag('onboarding_v2', ['control', 'treatment']),
    ]);
    floconFeatureFlags('statsig').register([
      flag('paywall_layout', ['variant_b', 'variant_a', 'control'], payload: '{"price": 4.99}'),
      flag('share_sheet', ['on', 'off']),
    ]);
  }

  static void registerDeeplinks() {
    floconRegisterDeeplinks(
      [
        const FloconDeeplink('flocondemo://home', label: 'Home'),
        const FloconDeeplink(
          'flocondemo://user/[userId]',
          label: 'User',
          description: 'Open the profile of a user',
          parameters: [FloconDeeplinkParameter.autoComplete('userId', ['Florent', 'David', 'Marie'])],
        ),
        const FloconDeeplink(
          'flocondemo://post/[postId]?comment=[comment]',
          label: 'Post',
          description: 'A post with a prefilled comment',
          parameters: [
            FloconDeeplinkParameter.autoComplete('postId', ['1', '2', '3']),
            FloconDeeplinkParameter.autoComplete('comment', ['Nice', 'Thanks']),
          ],
        ),
        const FloconDeeplink(
          'flocondemo://[env]/settings',
          label: 'Settings',
          parameters: [FloconDeeplinkParameter.variable('env', variableName: 'env')],
        ),
      ],
      variables: const [FloconDeeplinkVariable('env', description: 'Environment', suggestions: ['staging', 'production'])],
    );
  }

  static void startDashboard() {
    _dashboard?.dispose();
    _dashboard = floconDashboard('main', [
      FloconSection.listen<SampleUser>('User', user, (u) => [
            FloconText('name', u.name),
            FloconText('status', u.status, color: u.status == 'active' ? 0xFF4FD08A : 0xFFFF6D6D),
            FloconButton(
              'Log out',
              id: 'logout',
              onClick: () {
                user.value = user.value.copyWith(status: 'logged out');
                floconTimeline.logUserAction('dashboard_logout');
              },
            ),
            FloconTextField(
              id: 'rename',
              label: 'Rename',
              value: u.name,
              onSubmitted: (name) => user.value = user.value.copyWith(name: name),
            ),
            FloconCheckBox(
              id: 'premium',
              label: 'Premium',
              value: u.isPremium,
              onChanged: (value) => user.value = user.value.copyWith(isPremium: value),
            ),
          ]),
      const FloconSection('Build', [
        FloconPlainText('commit', 'a1b2c3d'),
        FloconJson('config', '{"api": "https://jsonplaceholder.typicode.com", "retries": 3}'),
        FloconMarkdown('Release note', '# 1.0\nFirst **release** of the sample'),
        FloconHtml('About', '<h1>Flocon sample</h1><p>Flutter</p>'),
      ]),
      FloconForm(
        'Create user',
        const [
          FloconTextField(id: 'name', label: 'Name', value: ''),
          FloconCheckBox(id: 'admin', label: 'Admin', value: false),
        ],
        submitText: 'Create',
        onSubmitted: (values) {
          user.value = SampleUser(name: values['name'] ?? '', status: 'active', isPremium: values['admin'] == 'true');
          floconTimeline.logUserAction('dashboard_create_user', params: values);
        },
      ),
    ]);
  }

  static Future<void> seedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', prefs.getString('username') ?? 'Florent');
    await prefs.setBool('dark_mode', prefs.getBool('dark_mode') ?? true);
    await prefs.setInt('launch_count', (prefs.getInt('launch_count') ?? 0) + 1);
    await prefs.setDouble('volume', prefs.getDouble('volume') ?? 0.8);
    await prefs.setStringList('tags', prefs.getStringList('tags') ?? ['flutter', 'flocon']);
  }
}

/// Opens the deeplinks of the sample inside the app.
class SampleDeeplinks {
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Returns false if the link is not one of the sample.
  static bool open(String link) {
    final uri = Uri.tryParse(link);
    final navigator = navigatorKey.currentState;
    if (uri == null || uri.scheme != 'flocondemo' || navigator == null) return false;
    final segments = [uri.host, ...uri.pathSegments];
    switch (segments.first) {
      case 'home':
        navigator.popUntil((route) => route.isFirst);
      case 'user' when segments.length > 1:
        navigator.pushNamed('/user/${segments[1]}');
      case 'post' when segments.length > 1:
        navigator.pushNamed('/post/${segments[1]}', arguments: uri.queryParameters['comment']);
      case 'staging' || 'production':
        navigator.pushNamed('/settings/${segments.first}');
      default:
        return false;
    }
    return true;
  }
}
