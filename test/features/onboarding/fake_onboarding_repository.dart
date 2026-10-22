import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';

/// An in-memory [OnboardingRepository] fake for onboarding tests.
class FakeOnboardingRepository implements OnboardingRepository {
  /// Creates a fake repository with the supplied initial snapshot.
  new({OnboardingSnapshot? initialSnapshot})
    : _snapshot = initialSnapshot ?? OnboardingSnapshot.initial;

  OnboardingSnapshot _snapshot;

  /// Every snapshot passed to [save].
  final List<OnboardingSnapshot> saved = <OnboardingSnapshot>[];

  /// Overrides the next [load] result once.
  Exception? loadError;

  /// Overrides the next [save] result once.
  Exception? saveError;

  @override
  Future<OnboardingSnapshot> load() async {
    final error = loadError;
    if (error != null) {
      loadError = null;
      throw error;
    }
    return _snapshot;
  }

  @override
  Future<void> save(OnboardingSnapshot snapshot) async {
    final error = saveError;
    if (error != null) {
      saveError = null;
      throw error;
    }
    saved.add(snapshot);
    _snapshot = snapshot;
  }
}
