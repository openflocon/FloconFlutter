/// There is no file system on the web: the callers log it and carry on without persistence.
Future<String> applicationSupportPath() => throw UnsupportedError(
  'There is no storage folder on the web.',
);
