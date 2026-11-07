import 'dart:convert';

/// The result of a query run from the desktop, in the format it expects: `{"type": ..., "body": "<json>"}`.
sealed class FloconDatabaseResult {
  const FloconDatabaseResult();

  String get type;
  Map<String, Object?> get body;

  String toJson() => jsonEncode({'type': type, 'body': jsonEncode(body)});
}

class FloconSelectResult extends FloconDatabaseResult {
  const FloconSelectResult(this.columns, this.values);

  final List<String> columns;

  /// One list per row, a value as text or null.
  final List<List<String?>> values;

  @override
  String get type => 'Select';
  @override
  Map<String, Object?> get body => {'columns': columns, 'values': values};
}

class FloconInsertResult extends FloconDatabaseResult {
  const FloconInsertResult(this.insertedId);
  final int insertedId;

  @override
  String get type => 'Insert';
  @override
  Map<String, Object?> get body => {'insertedId': insertedId};
}

class FloconUpdateDeleteResult extends FloconDatabaseResult {
  const FloconUpdateDeleteResult(this.affectedCount);
  final int affectedCount;

  @override
  String get type => 'UpdateDelete';
  @override
  Map<String, Object?> get body => {'affectedCount': affectedCount};
}

class FloconRawSuccessResult extends FloconDatabaseResult {
  const FloconRawSuccessResult();

  @override
  String get type => 'RawSuccess';
  @override
  Map<String, Object?> get body => const {};
}

class FloconErrorResult extends FloconDatabaseResult {
  const FloconErrorResult(this.message, this.originalSql);
  final String message;
  final String originalSql;

  @override
  String get type => 'Error';
  @override
  Map<String, Object?> get body => {'message': message, 'originalSql': originalSql};
}
