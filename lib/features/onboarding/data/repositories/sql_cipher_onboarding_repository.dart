import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

/// Persists the onboarding snapshot in the encrypted local database.
///
/// The snapshot is kept in a single row so the onboarding progress survives
/// a restart of the application.
class SqlCipherOnboardingRepository implements OnboardingRepository {
  /// Creates a repository that opens the database through [opener].
  const new({required this.opener});

  /// Opens the encrypted database when the snapshot is needed.
  final Future<Database> Function() opener;

  /// The singleton row id of the onboarding table.
  static const int rowId = 0;

  @override
  Future<OnboardingSnapshot> load() async {
    final database = await opener();
    final rows = await database.query(
      'onboarding',
      where: 'id = ?',
      whereArgs: <Object?>[rowId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return OnboardingSnapshot.initial;
    }

    return _snapshotFromRow(rows.single);
  }

  @override
  Future<void> save(OnboardingSnapshot snapshot) async {
    final database = await opener();
    await database.insert('onboarding', <String, Object?>{
      'id': rowId,
      'current_step': snapshot.currentStep.name,
      'is_completed': snapshot.isCompleted ? 1 : 0,
      'biometrics_enabled': snapshot.biometricsEnabled ? 1 : 0,
      'sms_automation_enabled': snapshot.smsAutomationEnabled ? 1 : 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Reads a stored row, falling back to the first step for an unknown one.
  OnboardingSnapshot _snapshotFromRow(Map<String, Object?> row) {
    final storedStep = row['current_step'];
    final currentStep = OnboardingStep.values.firstWhere(
      (step) => step.name == storedStep,
      orElse: () => OnboardingStep.privacy,
    );

    return OnboardingSnapshot(
      currentStep: currentStep,
      isCompleted: row['is_completed'] == 1,
      biometricsEnabled: row['biometrics_enabled'] == 1,
      smsAutomationEnabled: row['sms_automation_enabled'] == 1,
    );
  }
}
