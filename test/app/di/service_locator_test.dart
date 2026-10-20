import 'package:finecho/app/bootstrap/app_bootstrap.dart';
import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/features/analytics/data/repositories/in_memory_analytics_repository.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/in_memory_security_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  test('registers the budget dependency graph', () async {
    await configureDependencies();

    expect(sl<BudgetRepository>(), isA<BudgetRepository>());
    expect(sl<BudgetService>().listBudgets(), completion(isEmpty));
    expect(sl<BudgetCubit>().state.status, BudgetStatus.loading);
    await sl<BudgetCubit>().close();
  });

  test('shares one budget repository across the graph', () async {
    await configureDependencies();
    final repository = sl<BudgetRepository>();

    expect(identical(repository, sl<BudgetRepository>()), isTrue);
    await sl<CategoryRepository>().create(
      const Category(
        id: 'category-1',
        name: 'Food',
        iconKey: 'restaurant',
        colorHex: '#FF5722',
      ),
    );
    await sl<BudgetService>().createBudget(
      categoryId: 'category-1',
      allocatedAmountMinorUnits: 1000,
      period: 'monthly',
      startDate: DateTime.utc(2026, 10),
    );

    expect(await repository.list(), hasLength(1));
    await sl<BudgetCubit>().close();
  });

  test('registers in-memory security repositories by default', () async {
    await configureDependencies();

    expect(sl<SecurityRepository>(), isA<InMemorySecurityRepository>());
    expect(
      sl<SecurityCredentialRepository>(),
      isA<InMemorySecurityCredentialRepository>(),
    );
  });

  test(
    'registers secure platform security repositories when requested',
    () async {
      await configureDependencies(useSecureStorage: true);

      expect(sl<SecurityRepository>(), isA<SecureStorageSecurityRepository>());
      expect(
        sl<SecurityCredentialRepository>(),
        isA<SecureStorageSecurityCredentialRepository>(),
      );
      final stateRepository =
          sl<SecurityRepository>() as SecureStorageSecurityRepository;
      final credentialRepository =
          sl<SecurityCredentialRepository>()
              as SecureStorageSecurityCredentialRepository;
      expect(
        identical(stateRepository.store, credentialRepository.store),
        isTrue,
      );
    },
  );

  test('forwards secure storage configuration from bootstrap', () async {
    await AppBootstrap.ensureInitialized(useSecureStorage: true);

    expect(sl<SecurityRepository>(), isA<SecureStorageSecurityRepository>());
    expect(
      sl<SecurityCredentialRepository>(),
      isA<SecureStorageSecurityCredentialRepository>(),
    );
  });

  test('registers the analytics dependency graph', () async {
    await configureDependencies();

    expect(sl<AnalyticsRepository>(), isA<InMemoryAnalyticsRepository>());
    expect(sl<AnalyticsCubit>().state.status, AnalyticsStatus.loading);
    final dashboard = await sl<AnalyticsService>().loadDashboard(
      period: AnalyticsPeriod.month,
    );

    expect(dashboard.totalIncomeMinorUnits, isZero);
    expect(dashboard.totalExpenseMinorUnits, isZero);
    expect(dashboard.categoryTotals, isEmpty);
    await sl<AnalyticsCubit>().close();
  });

  test('shares one analytics repository across the graph', () async {
    await configureDependencies();
    final repository = sl<AnalyticsRepository>();

    expect(identical(repository, sl<AnalyticsRepository>()), isTrue);
    await sl<AnalyticsCubit>().close();
  });

  test('reads transactions seeded through the shared repositories', () async {
    await configureDependencies();
    final now = DateTime.now().toUtc();
    await sl<CategoryRepository>().create(
      const Category(
        id: 'category-1',
        name: 'Food',
        iconKey: 'restaurant',
        colorHex: '#FF5722',
      ),
    );
    await sl<TransactionRepository>().create(
      Transaction(
        id: 'tx-1',
        accountId: 'account-1',
        amountMinorUnits: 1234,
        timestamp: DateTime.utc(now.year, now.month, 1, 12),
        type: TransactionType.expense,
        source: TransactionSource.manual,
        categoryId: 'category-1',
      ),
    );

    final dashboard = await sl<AnalyticsService>().loadDashboard(
      period: AnalyticsPeriod.month,
    );

    expect(dashboard.totalExpenseMinorUnits, 1234);
    await sl<AnalyticsCubit>().close();
  });
}
