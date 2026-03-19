import 'package:ai_case_assistant/features/intake/data/local/tables/intake_sessions.dart';
import 'package:drift/drift.dart';

class IntakeSessionAttachments extends Table {
  @override
  String get tableName => 'intake_session_attachments';

  TextColumn get id => text()();

  TextColumn get sessionId => text().references(IntakeSessions, #id)();

  TextColumn get filePath => text()();

  TextColumn get fileType => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
