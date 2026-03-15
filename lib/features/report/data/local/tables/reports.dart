import 'package:drift/drift.dart';

class Reports extends Table {
  @override
  String get tableName => 'reports';

  TextColumn get id => text()();

  TextColumn get reportType => text()();

  DateTimeColumn get rangeStart => dateTime()();

  DateTimeColumn get rangeEnd => dateTime()();

  TextColumn get title => text()();

  TextColumn get summary => text()();

  TextColumn get adviceJson => text()();

  TextColumn get markdown => text()();

  DateTimeColumn get generatedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
