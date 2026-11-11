import 'dart:io';

import '../config.dart';
import '../core/logger.dart';
import '../core/storage.dart';

/// Where the last desktop address the SDK connected to is kept between two launches.
abstract interface class FloconAddressStore {
  Future<String?> load();
  Future<void> save(String address);
  Future<void> clear();
}

/// Keeps the address in a file of the storage folder.
class FloconFileAddressStore implements FloconAddressStore {
  FloconFileAddressStore(this._config);

  final FloconConfig _config;

  Future<File> _file() async =>
      File('${(await floconStorageDirectory(_config)).path}/last_address.txt');

  @override
  Future<String?> load() async {
    try {
      final file = await _file();
      return await file.exists() ? (await file.readAsString()).trim() : null;
    } catch (e) {
      FloconLogger.logError('Cannot read the last address', e);
      return null;
    }
  }

  @override
  Future<void> save(String address) async {
    try {
      await (await _file()).writeAsString(address);
    } catch (e) {
      FloconLogger.logError('Cannot save the last address', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
