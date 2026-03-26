import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(database.close);

  return database;
});
