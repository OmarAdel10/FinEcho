import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_account_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_category_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_transaction_repository.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/data/repositories/in_memory_onboarding_repository.dart';
import 'package:finecho/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';
import 'package:finecho/features/transactions/view_model/services/transaction_service.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
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
    ..registerLazySingleton<BudgetRepository>(
      InMemoryBudgetRepository.new,
    )
    ..registerLazySingleton<BudgetService>(
      () => BudgetService(
        budgets: sl<BudgetRepository>(),
        categories: sl<CategoryRepository>(),
      ),
    )
    ..registerLazySingleton<BudgetCubit>(
      () => BudgetCubit(sl<BudgetService>()),
    )
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
