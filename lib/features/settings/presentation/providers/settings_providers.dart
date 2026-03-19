import 'dart:async';

import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) {
      return SettingsRepository(database: ref.watch(appDatabaseProvider));
    });

final AsyncNotifierProvider<FollowUpModeController, bool>
followUpModeEnabledProvider =
    AsyncNotifierProvider<FollowUpModeController, bool>(
      FollowUpModeController.new,
    );

class FollowUpModeController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return ref.read(settingsRepositoryProvider).getFollowUpModeEnabled();
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncData<bool>(value);
    await ref.read(settingsRepositoryProvider).setFollowUpModeEnabled(value);
    state = AsyncData<bool>(value);
  }
}
