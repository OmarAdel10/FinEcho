import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';

/// Persists FinEcho's first-run onboarding state.
abstract interface class OnboardingRepository {
  /// Returns the current onboarding snapshot.
  Future<OnboardingSnapshot> load();

  /// Stores the supplied onboarding snapshot.
  Future<void> save(OnboardingSnapshot snapshot);
}
