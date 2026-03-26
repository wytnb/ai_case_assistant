import 'package:drift/drift.dart';

class HealthEvents extends Table {
  @override
  String get tableName => 'health_events';

  TextColumn get id => text()();

  TextColumn get sourceType => text()();

  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get rawText => text().nullable()();

  TextColumn get symptomSummary => text().nullable()();

  TextColumn get notes => text().nullable()();

  TextColumn get actionAdvice => text().nullable()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
