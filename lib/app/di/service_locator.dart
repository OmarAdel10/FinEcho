import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/in_memory_onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';
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
    ..registerLazySingleton<SecurityRepository>(InMemorySecurityRepository.new)
    ..registerLazySingleton<SecurityCredentialRepository>(
      InMemorySecurityCredentialRepository.new,
    )
    ..registerLazySingleton<SecurityService>(
      () => SecurityService(
        repository: sl<SecurityRepository>(),
        credentials: sl<SecurityCredentialRepository>(),
      ),
    )
    ..registerLazySingleton<SecurityCubit>(
      () => SecurityCubit(sl<SecurityService>()),
    )
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
