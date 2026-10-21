import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_account_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_category_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_transaction_repository.dart';
import 'package:finecho/features/analytics/data/repositories/in_memory_analytics_repository.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:finecho/features/onboarding/data/repositories/in_memory_onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';
import 'package:finecho/features/transactions/view_model/services/transaction_service.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:get_it/get_it.dart';

/// The application service locator.
final GetIt sl = GetIt.instance;

/// Registers the initial application-wide dependencies.
///
/// Secure storage is the default so a new entry point cannot silently fall
/// back to a non-persistent app lock. Tests opt into the in-memory graph
/// explicitly.
Future<void> configureDependencies({
  Environment environment = Environment.development,
  bool useInMemoryStorage = false,
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
    );

  if (useInMemoryStorage) {
    sl
      ..registerLazySingleton<SecurityRepository>(
        InMemorySecurityRepository.new,
      )
      ..registerLazySingleton<SecurityCredentialRepository>(
        InMemorySecurityCredentialRepository.new,
      );
  } else {
    const store = FlutterSecureKeyValueStore();
    sl
      ..registerLazySingleton<SecurityRepository>(
        () => const SecureStorageSecurityRepository(store: store),
      )
      ..registerLazySingleton<SecurityCredentialRepository>(
        () => const SecureStorageSecurityCredentialRepository(store: store),
      );
  }

  sl
    ..registerLazySingleton<SecurityService>(
      () => SecurityService(
        repository: sl<SecurityRepository>(),
        credentials: sl<SecurityCredentialRepository>(),
      ),
    )
    ..registerLazySingleton<SecurityCubit>(
      () => SecurityCubit(sl<SecurityService>()),
    )
    ..registerLazySingleton<TransactionRepository>(
      InMemoryTransactionRepository.new,
    )
    ..registerLazySingleton<AccountRepository>(InMemoryAccountRepository.new)
    ..registerLazySingleton<CategoryRepository>(InMemoryCategoryRepository.new)
    ..registerLazySingleton<TransactionService>(
      () => TransactionService(
        transactions: sl<TransactionRepository>(),
        accounts: sl<AccountRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    )
    ..registerLazySingleton<TransactionsCubit>(
      () => TransactionsCubit(sl<TransactionService>()),
    )
    ..registerLazySingleton<BudgetRepository>(InMemoryBudgetRepository.new)
    ..registerLazySingleton<BudgetService>(
      () => BudgetService(
        budgets: sl<BudgetRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    )
    ..registerLazySingleton<BudgetCubit>(() => BudgetCubit(sl<BudgetService>()))
    ..registerLazySingleton<AnalyticsRepository>(
      () => InMemoryAnalyticsRepository(
        transactions: sl<TransactionRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(
        analytics: sl<AnalyticsRepository>(),
        transactions: sl<TransactionRepository>(),
        accounts: sl<AccountRepository>(),
        budgets: sl<BudgetRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    )
    ..registerLazySingleton<AnalyticsCubit>(
      () => AnalyticsCubit(sl<AnalyticsService>()),
    )
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
