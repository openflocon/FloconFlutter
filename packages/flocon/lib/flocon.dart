/// Flocon SDK for Flutter: sends your app's network calls to the Flocon desktop app.
library;

export 'src/config.dart';
export 'src/client/address.dart' show FloconAddress, FloconAddressError;
export 'src/client/connection_state.dart';
export 'src/client/file_uploader.dart'
    show FloconFileUploader, FloconUploadIdentity;
export 'src/core/logger.dart' show FloconLogger;
export 'src/core/plugin.dart';
export 'src/flocon.dart';
export 'src/platform_registration.dart' show FloconDartPlugin;
export 'src/start.dart';
export 'src/model/message_from_server.dart';
export 'src/plugins/analytics/analytics_plugin.dart';
export 'src/plugins/dashboard/dashboard_content.dart' show FloconDashboardContent, FloconForm, FloconSection;
export 'src/plugins/dashboard/dashboard_elements.dart';
export 'src/plugins/dashboard/dashboard_plugin.dart' show FloconDashboardHandle, FloconDashboardPlugin, floconDashboard;
export 'src/plugins/deeplinks/deeplinks_plugin.dart' show FloconDeeplink, FloconDeeplinkParameter, FloconDeeplinkVariable, FloconDeeplinksPlugin, floconRegisterDeeplinks;
export 'src/plugins/feature_flags/feature_flags_plugin.dart' show FloconFeatureFlag, FloconFeatureFlagState, FloconFeatureFlags, FloconFeatureFlagsPlugin, floconFeatureFlags;
export 'src/plugins/table/table_plugin.dart';
export 'src/plugins/timeline/timeline_observers.dart';
export 'src/plugins/timeline/timeline_plugin.dart';
export 'src/plugins/network/network_options.dart';
export 'src/plugins/network/network_overrides.dart';
export 'src/plugins/network/network_plugin.dart';
export 'src/plugins/network/web_socket_event.dart';
