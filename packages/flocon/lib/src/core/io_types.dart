// `File` and `Directory` of `dart:io` where it exists, inert stand-ins on the web, so that the public API
// compiles everywhere. On the web the SDK never touches the file system.
export 'dart:io'
    if (dart.library.js_interop) 'io_types_stub.dart'
    show File, Directory;
