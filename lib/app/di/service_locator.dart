import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/onboarding/data/repositories/in_memory_onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:get_it/get_it.dart';

/// The application service locator.
final GetIt sl = GetIt.instance;

/// Registers the initial application-wide dependencies.
Future<void> configureDependencies({
  Environment environment = Environment.development,
}) async {
  sl
    ..registerSingleton<EnvironmentConfig>(EnvironmentConfig(environment))
    ..registerLazySingleton<OnboardingRepository>(
      InMemoryOnboardingRepository.new,
    )
    ..registerLazySingleton<OnboardingService>(
      () => OnboardingService(sl<OnboardingRepository>()),
    )
    ..registerLazySingleton<OnboardingCubit>(
      () => OnboardingCubit(sl<OnboardingService>()),
    )
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
