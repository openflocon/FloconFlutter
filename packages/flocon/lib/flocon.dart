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
export 'src/model/message_from_server.dart';
export 'src/plugins/analytics/analytics_plugin.dart';
export 'src/plugins/table/table_plugin.dart';
export 'src/plugins/network/network_overrides.dart';
export 'src/plugins/network/network_plugin.dart';
export 'src/plugins/network/web_socket_event.dart';
