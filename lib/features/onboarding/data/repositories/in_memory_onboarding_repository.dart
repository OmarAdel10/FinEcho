import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';

/// An in-memory onboarding store used until durable storage is integrated.
class InMemoryOnboardingRepository implements OnboardingRepository {
  /// Creates a repository that starts at the first onboarding step.
  new({OnboardingSnapshot? initialSnapshot})
    : _snapshot = initialSnapshot ?? OnboardingSnapshot.initial;

  OnboardingSnapshot _snapshot;

  @override
  Future<OnboardingSnapshot> load() async => _snapshot;

  @override
  Future<void> save(OnboardingSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
