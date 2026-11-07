import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Object body})>[];
  @override
  void send({required String plugin, required String method, required String body}) =>
      sent.add((plugin: plugin, method: method, body: jsonDecode(body) as Object));
}

class _Recorder extends FloconTimeline {
  final events = <String>[];
  @override
  void log(TimelineType type, String value, {Map<String, String> params = const {}}) =>
      events.add('${type.name}:$value:${params.entries.map((e) => '${e.key}=${e.value}').join(',')}');
}

void main() {
  group('timeline', () {
    test('typed events have no level, empty params are omitted, the timestamp is the moment of the call', () {
      final sender = _Sender();
      final plugin = FloconTimelinePlugin(sender: sender, now: () => DateTime.fromMillisecondsSinceEpoch(1234));
      plugin.send(type: 'navigation', value: 'Home');
      final message = sender.sent.single;
      expect((message.plugin, message.method), ('timeline', 'log'));
      expect(message.body, {'type': 'navigation', 'value': 'Home', 'timestamp': 1234});
    });

    test('tagged events carry their level and params', () {
      final sender = _Sender();
      final plugin = FloconTimelinePlugin(sender: sender);
      plugin.send(type: 'billing', value: 'Purchase failed', params: {'sku': 'pro'}, level: TimelineLevel.error);
      final body = sender.sent.single.body as Map<String, dynamic>;
      expect(body['level'], 'error');
      expect(body['params'], {'sku': 'pro'});
      expect(body['type'], 'billing');
    });

    test('reserved types', () {
      expect([TimelineType.navigation.name, TimelineType.userAction.name, TimelineType.lifecycle.name], ['navigation', 'userAction', 'lifecycle']);
      expect(const TimelineType('x'), const TimelineType('x'));
    });

    test('the facade does nothing before initialize', () {
      floconTimeline.logNavigation('Home');
      floconTimeline.logTagged('t', 'v');
    });

    test('the navigator observer logs pushes, pops and replacements', () {
      final recorder = _Recorder();
      final observer = FloconNavigatorObserver(timeline: recorder);
      Route<void> route(String name) => MaterialPageRoute<void>(settings: RouteSettings(name: name), builder: (_) => const SizedBox());
      final home = route('/home'), detail = route('/detail');
      observer.didPush(home, null);
      observer.didPush(detail, home);
      observer.didPop(detail, home);
      observer.didReplace(newRoute: detail, oldRoute: home);
      observer.didPop(home, null); // nothing to go back to
      expect(recorder.events, [
        'navigation:/home:action=push',
        'navigation:/detail:from=/home,action=push',
        'navigation:/home:from=/detail,action=pop',
        'navigation:/detail:from=/home,action=replace',
      ]);
    });

    testWidgets('the lifecycle observer logs the states, and starts once', (tester) async {
      final recorder = _Recorder();
      FloconLifecycleObserver.start(timeline: recorder);
      FloconLifecycleObserver.start(timeline: recorder);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      FloconLifecycleObserver.stop();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(recorder.events.where((e) => e.startsWith('lifecycle:')), ['lifecycle:paused:', 'lifecycle:resumed:']);
    });
  });

  group('feature flags', () {
    test('register sends the flags of the provider, omitting a missing payload', () {
      final sender = _Sender();
      FloconFeatureFlagsPlugin(sender: sender).register('firebase', const [
        FloconFeatureFlag(name: 'new_checkout', state: FloconFeatureFlagState.custom, variant: 'treatment', payload: '{"steps":3}'),
        FloconFeatureFlag(name: 'dark_mode', state: FloconFeatureFlagState.on, variant: 'on'),
      ]);
      final message = sender.sent.single;
      expect((message.plugin, message.method), ('feature_flags', 'register'));
      expect(message.body, {
        'provider': 'firebase',
        'flags': [
          {'name': 'new_checkout', 'state': 'custom', 'variant': 'treatment', 'payload': '{"steps":3}'},
          {'name': 'dark_mode', 'state': 'on', 'variant': 'on'},
        ],
      });
    });

    test('each call replaces the flags of the provider, and all providers are sent again on connection', () {
      final sender = _Sender();
      final plugin = FloconFeatureFlagsPlugin(sender: sender);
      plugin.register('b', const [FloconFeatureFlag(name: 'x', state: FloconFeatureFlagState.off, variant: 'off')]);
      plugin.register('a', const [FloconFeatureFlag(name: 'y', state: FloconFeatureFlagState.on, variant: 'on')]);
      plugin.register('b', const [FloconFeatureFlag(name: 'z', state: FloconFeatureFlagState.on, variant: 'on')]);
      sender.sent.clear();
      plugin.onConnectedToServer();
      final bodies = sender.sent.map((m) => m.body as Map<String, dynamic>).toList();
      expect(bodies.map((b) => b['provider']), ['a', 'b']);
      expect(((bodies.last['flags'] as List).single as Map)['name'], 'z');
    });

    test('the facade does nothing before initialize', () {
      floconFeatureFlags('firebase').register(const []);
    });
  });

  group('deeplinks', () {
    test('sends the links, parameters and variables in the desktop format', () {
      final sender = _Sender();
      FloconDeeplinksPlugin(sender: sender).register(
        [
          const FloconDeeplink('myapp://home', label: 'Home'),
          const FloconDeeplink(
            'myapp://user/[userId]',
            description: 'Open a profile',
            parameters: [FloconDeeplinkParameter.autoComplete('userId', ['Florent', 'David'])],
          ),
          const FloconDeeplink('myapp://[env]/settings', parameters: [FloconDeeplinkParameter.variable('env', variableName: 'env')]),
        ],
        variables: const [
          FloconDeeplinkVariable('env', suggestions: ['staging', 'production']),
          FloconDeeplinkVariable('free', description: 'Any text'),
        ],
      );
      final message = sender.sent.single;
      expect((message.plugin, message.method), ('deeplink', 'get_deeplinks'));
      expect(message.body, {
        'deeplinks': [
          {'label': 'Home', 'link': 'myapp://home', 'parameters': <Object>[]},
          {
            'link': 'myapp://user/[userId]',
            'description': 'Open a profile',
            'parameters': [
              {'type': 'auto_complete', 'name': 'userId', 'autoComplete': ['Florent', 'David']},
            ],
          },
          {
            'link': 'myapp://[env]/settings',
            'parameters': [
              {'type': 'variable', 'name': 'env', 'variableName': 'env'},
            ],
          },
        ],
        'variables': [
          {'name': 'env', 'mode': {'type': 'auto_complete', 'suggestions': ['staging', 'production']}},
          {'name': 'free', 'description': 'Any text'},
        ],
      });
    });

    test('the list is sent again on connection, nothing before a registration', () {
      final sender = _Sender();
      final plugin = FloconDeeplinksPlugin(sender: sender);
      plugin.onConnectedToServer();
      expect(sender.sent, isEmpty);
      plugin.register(const [FloconDeeplink('myapp://home')]);
      plugin.onConnectedToServer();
      expect(sender.sent, hasLength(2));
    });

    test('the facade does nothing before initialize', () {
      floconRegisterDeeplinks(const [FloconDeeplink('myapp://home')]);
    });
  });
}
