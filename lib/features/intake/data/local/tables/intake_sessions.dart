import 'package:drift/drift.dart';

class IntakeSessions extends Table {
  @override
  String get tableName => 'intake_sessions';

  TextColumn get id => text()();

  TextColumn get healthEventId => text().nullable()();

  DateTimeColumn get eventTime => dateTime()();

  BoolColumn get followUpModeSnapshot => boolean()();

  TextColumn get status => text()();

  TextColumn get initialRawText => text()();

  TextColumn get mergedRawText => text().nullable()();

  TextColumn get latestQuestion => text().nullable()();

  TextColumn get draftSymptomSummary => text().nullable()();

  TextColumn get draftNotes => text().nullable()();

  TextColumn get draftActionAdvice => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
