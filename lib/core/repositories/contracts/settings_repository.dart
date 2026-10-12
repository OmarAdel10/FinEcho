import 'package:finecho/core/models/app_setting.dart';

/// Persists and reads string-valued FinEcho preferences.
abstract interface class SettingsRepository {
  /// Returns the setting for [key], or `null` when it does not exist.
  Future<AppSetting?> get(String key);

  /// Inserts or replaces the setting identified by [key].
  Future<void> set(String key, String value);

  /// Returns all settings ordered by key.
  Future<List<AppSetting>> list();

  /// Deletes the setting for [key].
  Future<void> delete(String key);
}
