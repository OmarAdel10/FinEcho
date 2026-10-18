import 'package:finecho/core/models/budget.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

void main() {
  test('performs the full repository contract', () async {
    final repository = InMemoryBudgetRepository();
    final budget = testBudget(id: 'memory-budget');

    expect(await repository.get('memory-budget'), isNull);
    expect(await repository.list(), isEmpty);

    await repository.create(budget);
    expect(await repository.get('memory-budget'), budget);
    expect(await repository.list(), <Budget>[budget]);

    final updated = budget.copyWith(allocatedAmountMinorUnits: 5000);
    await repository.update(updated);
    expect(await repository.get('memory-budget'), updated);
    expect(updated.allocatedAmountMinorUnits, 5000);

    await repository.delete('memory-budget');
    await repository.delete('memory-budget');
    expect(await repository.get('memory-budget'), isNull);
    expect(await repository.list(), isEmpty);
  });
}
