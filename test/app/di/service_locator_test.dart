import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
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
}
