/// JSON format of a crash, sent to the desktop app and saved on disk until then.
class FloconCrashReport {
  const FloconCrashReport({
    required this.crashId,
    required this.timestamp,
    required this.exceptionType,
    required this.exceptionMessage,
    required this.stackTrace,
  });

  factory FloconCrashReport.fromJson(Map<String, dynamic> json) => FloconCrashReport(
        crashId: json['crashId'] as String,
        timestamp: (json['timestamp'] as num).toInt(),
        exceptionType: json['exceptionType'] as String,
        exceptionMessage: json['exceptionMessage'] as String,
        stackTrace: json['stackTrace'] as String,
      );

  final String crashId;

  /// When the error happened, in milliseconds since 1970.
  final int timestamp;

  /// The runtime type of the error, for example `StateError`.
  final String exceptionType;
  final String exceptionMessage;
  final String stackTrace;

  Map<String, Object> toJson() => {
        'crashId': crashId,
        'timestamp': timestamp,
        'exceptionType': exceptionType,
        'exceptionMessage': exceptionMessage,
        'stackTrace': stackTrace,
      };
}
