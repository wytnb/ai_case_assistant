import 'package:ai_case_assistant/features/health_record/data/local/tables/health_events.dart';
import 'package:drift/drift.dart';

class Attachments extends Table {
  @override
  String get tableName => 'attachments';

  TextColumn get id => text()();

  TextColumn get healthEventId => text().references(HealthEvents, #id)();

  TextColumn get filePath => text()();

  TextColumn get fileType => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
