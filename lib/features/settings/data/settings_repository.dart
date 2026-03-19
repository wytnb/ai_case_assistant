import 'dart:convert';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:drift/drift.dart';

enum AppSettingValueType {
  boolType('bool'),
  intType('int'),
  doubleType('double'),
  stringType('string'),
  jsonType('json');

  const AppSettingValueType(this.storageValue);

  final String storageValue;
}

class SettingsRepository {
  SettingsRepository({required AppDatabase database}) : _database = database;

  static const String followUpModeEnabledKey = 'follow_up_mode_enabled';

  final AppDatabase _database;

  Future<bool> getFollowUpModeEnabled() async {
    final AppSetting? setting = await _database.getAppSettingByKey(
      followUpModeEnabledKey,
    );
    if (setting == null) {
      return false;
    }

    if (setting.valueType != AppSettingValueType.boolType.storageValue ||
        setting.boolValue == null) {
      return false;
    }

    return setting.boolValue!;
  }

  Future<void> setFollowUpModeEnabled(bool value) async {
    final DateTime now = _truncateToSeconds(DateTime.now());
    final AppSetting? existing = await _database.getAppSettingByKey(
      followUpModeEnabledKey,
    );
    await _database.upsertAppSetting(
      AppSettingsCompanion(
        key: const Value<String>(followUpModeEnabledKey),
        valueType: Value<String>(AppSettingValueType.boolType.storageValue),
        boolValue: Value<bool?>(value),
        intValue: const Value<int?>.absent(),
        doubleValue: const Value<double?>.absent(),
        stringValue: const Value<String?>.absent(),
        jsonValue: const Value<String?>.absent(),
        createdAt: Value<DateTime>(existing?.createdAt ?? now),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  Future<void> setJsonValue({
    required String key,
    required Object value,
  }) async {
    final DateTime now = _truncateToSeconds(DateTime.now());
    final AppSetting? existing = await _database.getAppSettingByKey(key);
    final String encoded = jsonEncode(value);
    await _database.upsertAppSetting(
      AppSettingsCompanion(
        key: Value<String>(key),
        valueType: Value<String>(AppSettingValueType.jsonType.storageValue),
        boolValue: const Value<bool?>.absent(),
        intValue: const Value<int?>.absent(),
        doubleValue: const Value<double?>.absent(),
        stringValue: const Value<String?>.absent(),
        jsonValue: Value<String?>(encoded),
        createdAt: Value<DateTime>(existing?.createdAt ?? now),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  DateTime _truncateToSeconds(DateTime value) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: value.isUtc,
    );
  }
}
