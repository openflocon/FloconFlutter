import '../../core/io_types.dart';

import '../../core/logger.dart';

/// Keeps the network mocks and the bad network configuration set from the desktop on disk, so that they apply from
/// the next launch too, before the app connects to the desktop.
class FloconNetworkStore {
  FloconNetworkStore(this._directory);

  final Future<Directory> Function() _directory;

  static const _mocksFile = 'flocon_network_mocks.json';
  static const _badNetworkFile = 'flocon_network_bad_config.json';

  Future<String?> loadMocks() => _read(_mocksFile);
  Future<String?> loadBadNetworkConfig() => _read(_badNetworkFile);

  Future<void> saveMocks(String? json) => _write(_mocksFile, json);
  Future<void> saveBadNetworkConfig(String? json) =>
      _write(_badNetworkFile, json);

  Future<File> _file(String name) async =>
      File('${(await _directory()).path}/network/$name');

  Future<String?> _read(String name) async {
    try {
      final file = await _file(name);
      return await file.exists() ? await file.readAsString() : null;
    } catch (e) {
      FloconLogger.logError('Cannot read the network configuration', e);
      return null;
    }
  }

  /// Deletes the file when [json] is null.
  Future<void> _write(String name, String? json) async {
    try {
      final file = await _file(name);
      if (json == null) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(json);
    } catch (e) {
      FloconLogger.logError('Cannot save the network configuration', e);
    }
  }
}
