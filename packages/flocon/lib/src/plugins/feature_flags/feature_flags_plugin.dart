import 'dart:convert';

import '../../core/plugin.dart';
import '../../flocon.dart';
import '../../model/message_from_server.dart';

/// Whether a [FloconFeatureFlag] is on, off, or on a custom variant.
enum FloconFeatureFlagState {
  on,
  off,

  /// Neither on nor off: an experiment arm (`'treatment'`, `'variant_b'`), a value...
  custom,
}

/// A feature flag as evaluated by the app, shown in the Feature Flags section of the Flocon desktop app.
class FloconFeatureFlag {
  const FloconFeatureFlag({
    required this.name,
    required this.state,
    required this.variant,
    this.payload,
  });

  /// Key of the flag, for example `'new_checkout'`.
  final String name;

  /// The desktop colors the variant with it.
  final FloconFeatureFlagState state;

  /// Evaluated variant, for example `'control'`, `'treatment'` or `'on'`.
  final String variant;

  /// Optional payload attached to the variant, often json.
  final String? payload;

  Map<String, Object> toJson() => {
        'name': name,
        'state': state.name,
        'variant': variant,
        if (payload != null) 'payload': payload!,
      };
}

/// Registers the feature flags of a provider in the Flocon desktop app. Use one provider per feature flag
/// system (Firebase Remote Config, Statsig, an in-house one...); no dependency on their SDKs. Each call replaces the
/// flags previously registered for the provider, and they are sent again when the app reconnects to the desktop.
///
/// ```dart
/// floconFeatureFlags('firebase').register([
///   FloconFeatureFlag(name: 'new_checkout', state: FloconFeatureFlagState.custom, variant: 'treatment', payload: '{"steps": 3}'),
///   FloconFeatureFlag(name: 'dark_mode', state: FloconFeatureFlagState.on, variant: 'on'),
/// ]);
/// ```
class FloconFeatureFlags {
  const FloconFeatureFlags._(this.provider);

  final String provider;

  /// Replaces the flags of the provider. Does nothing before `Flocon.initialize`.
  void register(List<FloconFeatureFlag> flags) => Flocon.featureFlagsPlugin?.register(provider, flags);
}

/// The registrar of a feature flag provider, for example `'firebase'`.
FloconFeatureFlags floconFeatureFlags(String provider) => FloconFeatureFlags._(provider);

/// Sends the feature flags of the app to the Flocon desktop app.
class FloconFeatureFlagsPlugin implements FloconPlugin {
  FloconFeatureFlagsPlugin({required FloconMessageSender sender}) : _sender = sender;

  static const name = 'feature_flags';
  static const methodRegister = 'register';

  final FloconMessageSender _sender;
  final _registered = <String, List<FloconFeatureFlag>>{};

  @override
  String get pluginName => name;

  /// Replaces the flags of a provider in the desktop app.
  void register(String provider, List<FloconFeatureFlag> flags) {
    _registered[provider] = List.of(flags);
    _send(provider, flags);
  }

  @override
  void onConnectedToServer() {
    for (final provider in _registered.keys.toList()..sort()) {
      _send(provider, _registered[provider]!);
    }
  }

  /// The desktop app is read only: it sends nothing to this plugin.
  @override
  void onMessageReceived(FloconMessageFromServer message) {}

  void _send(String provider, List<FloconFeatureFlag> flags) {
    try {
      _sender.send(
        plugin: pluginName,
        method: methodRegister,
        body: jsonEncode({'provider': provider, 'flags': [for (final f in flags) f.toJson()]}),
      );
    } catch (_) {}
  }
}
