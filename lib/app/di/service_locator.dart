import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/database/app_database.dart';
import 'package:finecho/core/database/database_opener.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_account_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_category_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_transaction_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_analytics_repository.dart';
import 'package:finecho/core/repositories/implementations/sqflite_budget_repository.dart';
import 'package:finecho/features/analytics/data/repositories/in_memory_analytics_repository.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:finecho/features/onboarding/data/repositories/in_memory_onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/sql_cipher_onboarding_repository.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/data/biometrics/biometric_authenticator.dart';
import 'package:finecho/features/security/data/biometrics/local_auth_biometric_authenticator.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/storage/database_key_store.dart';
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
  // Register environment config
  sl.registerSingleton<EnvironmentConfig>(EnvironmentConfig(environment));

  // Register database components
  sl.registerLazySingleton<DatabaseKeyStore>(
    () => const DatabaseKeyStore(store: FlutterSecureKeyValueStore()),
  );

  sl.registerLazySingleton<DatabaseOpener>(
    () => DatabaseOpener(
      passwordProvider: () async {
        final keyStore = sl<DatabaseKeyStore>();
        return await keyStore.readOrCreateKey();
      },
    ),
  );

  sl.registerLazySingleton<AppDatabase>(
    () => AppDatabase(opener: sl<DatabaseOpener>()),
  );

  // Register onboarding repository
  if (useInMemoryStorage) {
    sl.registerLazySingleton<OnboardingRepository>(
      InMemoryOnboardingRepository.new,
    );
  } else {
    sl.registerLazySingleton<OnboardingRepository>(
      () => SqlCipherOnboardingRepository(opener: sl<DatabaseOpener>().open),
    );
  }
  sl.registerLazySingleton<OnboardingService>(
    () => OnboardingService(sl<OnboardingRepository>()),
  );
  sl.registerLazySingleton<OnboardingCubit>(
    () => OnboardingCubit(sl<OnboardingService>()),
  );

  // Register security repositories
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

  // Register financial repositories (needed by the security reset).
  // Budgets persist in the encrypted database in production; tests opt into
  // the in-memory graph explicitly.
  sl
    ..registerLazySingleton<TransactionRepository>(
      InMemoryTransactionRepository.new,
    )
    ..registerLazySingleton<AccountRepository>(InMemoryAccountRepository.new)
    ..registerLazySingleton<CategoryRepository>(InMemoryCategoryRepository.new);
  if (useInMemoryStorage) {
    sl.registerLazySingleton<BudgetRepository>(InMemoryBudgetRepository.new);
  } else {
    sl.registerLazySingleton<BudgetRepository>(
      () => SqfliteBudgetRepository(opener: sl<DatabaseOpener>().open),
    );
  }

  // Register the platform biometric prompt, service, and cubit.
  sl
    ..registerLazySingleton<BiometricAuthenticator>(
      LocalAuthBiometricAuthenticator.new,
    )
    ..registerLazySingleton<SecurityService>(
      () => SecurityService(
        repository: sl<SecurityRepository>(),
        credentials: sl<SecurityCredentialRepository>(),
        transactionRepository: sl<TransactionRepository>(),
        accountRepository: sl<AccountRepository>(),
        categoryRepository: sl<CategoryRepository>(),
        budgetRepository: sl<BudgetRepository>(),
      ),
    )
    ..registerLazySingleton<SecurityCubit>(
      () => SecurityCubit(
        sl<SecurityService>(),
        biometrics: sl<BiometricAuthenticator>(),
      ),
    );

  // Register transaction components
  sl.registerLazySingleton<TransactionService>(
    () => TransactionService(
      transactions: sl<TransactionRepository>(),
      accounts: sl<AccountRepository>(),
      categories: sl<CategoryRepository>(),
    ),
  );
  sl.registerLazySingleton<TransactionsCubit>(
    () => TransactionsCubit(sl<TransactionService>()),
  );

  // Register budget components
  sl.registerLazySingleton<BudgetService>(
    () => BudgetService(
      budgets: sl<BudgetRepository>(),
      categories: sl<CategoryRepository>(),
    ),
  );
  sl.registerLazySingleton<BudgetCubit>(() => BudgetCubit(sl<BudgetService>()));

  // Register analytics components. Production aggregates with SQL over the
  // encrypted database; tests opt into the in-memory graph explicitly.
  if (useInMemoryStorage) {
    sl.registerLazySingleton<AnalyticsRepository>(
      () => InMemoryAnalyticsRepository(
        transactions: sl<TransactionRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    );
  } else {
    sl.registerLazySingleton<AnalyticsRepository>(
      () => SqfliteAnalyticsRepository(opener: sl<DatabaseOpener>().open),
    );
  }
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(
      analytics: sl<AnalyticsRepository>(),
      accounts: sl<AccountRepository>(),
      budgets: sl<BudgetRepository>(),
      categories: sl<CategoryRepository>(),
    ),
  );
  sl.registerLazySingleton<AnalyticsCubit>(
    () => AnalyticsCubit(sl<AnalyticsService>()),
  );

  // Register app router
  sl.registerLazySingleton<AppRouter>(AppRouter.new);
}
