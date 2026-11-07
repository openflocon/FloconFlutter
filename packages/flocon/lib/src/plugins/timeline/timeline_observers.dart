import 'package:flutter/widgets.dart';

import 'timeline_plugin.dart';

/// Logs the screen changes of a `Navigator` in the timeline.
///
/// ```dart
/// MaterialApp(navigatorObservers: [FloconNavigatorObserver()], ...)
/// ```
///
/// A route is named by its `RouteSettings.name`, otherwise by its type; give your routes names (or use a router
/// that does) to read them in the timeline.
class FloconNavigatorObserver extends NavigatorObserver {
  FloconNavigatorObserver({FloconTimeline timeline = floconTimeline}) : _timeline = timeline;

  final FloconTimeline _timeline;

  static String _name(Route<dynamic>? route) => route == null ? '' : (route.settings.name ?? route.runtimeType.toString());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _timeline.logNavigation(_name(route), params: {if (previousRoute != null) 'from': _name(previousRoute), 'action': 'push'});
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) return;
    _timeline.logNavigation(_name(previousRoute), params: {'from': _name(route), 'action': 'pop'});
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) return;
    _timeline.logNavigation(_name(newRoute), params: {if (oldRoute != null) 'from': _name(oldRoute), 'action': 'replace'});
  }
}

/// Logs the lifecycle of the app (resumed, inactive, paused, hidden, detached) in the timeline.
class FloconLifecycleObserver with WidgetsBindingObserver {
  FloconLifecycleObserver._({FloconTimeline timeline = floconTimeline}) : _timeline = timeline;

  final FloconTimeline _timeline;

  static FloconLifecycleObserver? _instance;

  /// Starts logging the lifecycle of the app. Calling it twice has no effect.
  static void start({FloconTimeline timeline = floconTimeline}) {
    if (_instance != null) return;
    WidgetsFlutterBinding.ensureInitialized();
    _instance = FloconLifecycleObserver._(timeline: timeline);
    WidgetsBinding.instance.addObserver(_instance!);
  }

  /// Stops logging the lifecycle.
  static void stop() {
    final observer = _instance;
    if (observer == null) return;
    WidgetsBinding.instance.removeObserver(observer);
    _instance = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _timeline.logLifecycle(state.name);
}
