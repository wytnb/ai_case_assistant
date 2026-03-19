import 'package:ai_case_assistant/features/intake/data/local/tables/intake_sessions.dart';
import 'package:drift/drift.dart';

class IntakeMessages extends Table {
  @override
  String get tableName => 'intake_messages';

  TextColumn get id => text()();

  TextColumn get sessionId => text().references(IntakeSessions, #id)();

  IntColumn get seq => integer()();

  TextColumn get role => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{sessionId, seq},
  ];
}
