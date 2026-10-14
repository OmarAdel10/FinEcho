import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';

/// Coordinates FinEcho's onboarding business rules and persistence.
class OnboardingService {
  /// Creates an onboarding service.
  const new(this._repository);

  final OnboardingRepository _repository;

  /// Loads the current onboarding snapshot.
  Future<OnboardingSnapshot> load() => _repository.load();

  /// Persists the supplied onboarding snapshot.
  Future<OnboardingSnapshot> save(OnboardingSnapshot snapshot) async {
    await _repository.save(snapshot);
    return snapshot;
  }
}
