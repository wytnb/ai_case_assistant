import 'package:drift/drift.dart';

class HealthEvents extends Table {
  @override
  String get tableName => 'health_events';

  TextColumn get id => text()();

  DateTimeColumn get eventTime => dateTime()();

  TextColumn get sourceType => text()();

  TextColumn get rawText => text().nullable()();

  TextColumn get symptomSummary => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
