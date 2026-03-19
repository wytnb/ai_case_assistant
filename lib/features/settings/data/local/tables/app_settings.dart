import 'package:drift/drift.dart';

class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();

  TextColumn get valueType => text()();

  BoolColumn get boolValue => boolean().nullable()();

  IntColumn get intValue => integer().nullable()();

  RealColumn get doubleValue => real().nullable()();

  TextColumn get stringValue => text().nullable()();

  TextColumn get jsonValue => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (value_type IN ('bool', 'int', 'double', 'string', 'json'))",
    '''
    CHECK (
      (value_type = 'bool' AND bool_value IS NOT NULL AND int_value IS NULL AND double_value IS NULL AND string_value IS NULL AND json_value IS NULL) OR
      (value_type = 'int' AND bool_value IS NULL AND int_value IS NOT NULL AND double_value IS NULL AND string_value IS NULL AND json_value IS NULL) OR
      (value_type = 'double' AND bool_value IS NULL AND int_value IS NULL AND double_value IS NOT NULL AND string_value IS NULL AND json_value IS NULL) OR
      (value_type = 'string' AND bool_value IS NULL AND int_value IS NULL AND double_value IS NULL AND string_value IS NOT NULL AND json_value IS NULL) OR
      (value_type = 'json' AND bool_value IS NULL AND int_value IS NULL AND double_value IS NULL AND string_value IS NULL AND json_value IS NOT NULL)
    )
    ''',
  ];
}
