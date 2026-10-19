import 'dart:async';

import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_analytics_repositories.dart';

void main() {
  group('AnalyticsCubit', () {
    test('loads the dashboard and emits loading then ready', () async {
      final harness = AnalyticsTestHarness();
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      final expectations = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AnalyticsState>()
              .having(
                (state) => state.status,
                'status',
                AnalyticsStatus.loading,
              )
              .having((state) => state.dashboard, 'dashboard', isNull),
          isA<AnalyticsState>()
              .having((state) => state.status, 'status', AnalyticsStatus.ready)
              .having((state) => state.dashboard, 'dashboard', isNotNull),
        ]),
      );

      await cubit.load();
      await expectations;

      expect(cubit.state.period, AnalyticsPeriod.month);
      expect(harness.analyticsRepository.requestedRanges, hasLength(2));
    });

    test('emits a failure state when the dashboard cannot load', () async {
      final harness = AnalyticsTestHarness();
      harness.analyticsRepository.error = Exception('boom');
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, AnalyticsStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not load your statistics. Please try again.',
      );
      expect(cubit.state.dashboard, isNull);
    });

    test('selects a new period and reloads its ranges', () async {
      final harness = AnalyticsTestHarness();
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      await cubit.load();

      final expectations = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AnalyticsState>()
              .having(
                (state) => state.status,
                'status',
                AnalyticsStatus.loading,
              )
              .having((state) => state.period, 'period', AnalyticsPeriod.year),
          isA<AnalyticsState>()
              .having((state) => state.status, 'status', AnalyticsStatus.ready)
              .having((state) => state.period, 'period', AnalyticsPeriod.year),
        ]),
      );

      await cubit.selectPeriod(AnalyticsPeriod.year);
      await expectations;

      expect(harness.analyticsRepository.requestedRanges, [
        (DateTime.utc(2026, 10), DateTime.utc(2026, 11)),
        (DateTime.utc(2026, 9), DateTime.utc(2026, 9, 16)),
        (DateTime.utc(2026), DateTime.utc(2027)),
        (DateTime.utc(2025), DateTime.utc(2025, 10, 16)),
      ]);
      expect(cubit.state.period, AnalyticsPeriod.year);
    });

    test('does nothing when the selected period is unchanged', () async {
      final harness = AnalyticsTestHarness();
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      await cubit.load();

      var emissions = 0;
      final subscription = cubit.stream.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      await cubit.selectPeriod(AnalyticsPeriod.month);

      expect(emissions, 0);
      expect(harness.analyticsRepository.requestedRanges, hasLength(2));
    });

    test('ignores a reload while one is in flight', () async {
      final harness = AnalyticsTestHarness();
      final gate = Completer<void>();
      harness.analyticsRepository.gate = gate;
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      final firstLoad = cubit.load();
      final secondLoad = cubit.load();
      gate.complete();
      await Future.wait([firstLoad, secondLoad]);

      expect(harness.analyticsRepository.requestedRanges, hasLength(2));
      expect(cubit.state.status, AnalyticsStatus.ready);
    });

    test('queues a period change that arrives while loading', () async {
      final harness = AnalyticsTestHarness();
      final gate = Completer<void>();
      harness.analyticsRepository.gate = gate;
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      final load = cubit.load();
      final select = cubit.selectPeriod(AnalyticsPeriod.year);
      gate.complete();
      await Future.wait([load, select]);

      expect(cubit.state.period, AnalyticsPeriod.year);
      expect(cubit.state.status, AnalyticsStatus.ready);
      expect(harness.analyticsRepository.requestedRanges, [
        (DateTime.utc(2026, 10), DateTime.utc(2026, 11)),
        (DateTime.utc(2026, 9), DateTime.utc(2026, 9, 16)),
        (DateTime.utc(2026), DateTime.utc(2027)),
        (DateTime.utc(2025), DateTime.utc(2025, 10, 16)),
      ]);
    });

    test('keeps the dashboard when a reload fails', () async {
      final harness = AnalyticsTestHarness();
      final cubit = AnalyticsCubit(harness.service);
      addTearDown(cubit.close);

      await cubit.load();
      final dashboard = cubit.state.dashboard;

      harness.analyticsRepository.error = Exception('boom');
      final expectations = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AnalyticsState>()
              .having(
                (state) => state.status,
                'status',
                AnalyticsStatus.loading,
              )
              .having((state) => state.dashboard, 'dashboard', dashboard),
          isA<AnalyticsState>()
              .having(
                (state) => state.status,
                'status',
                AnalyticsStatus.failure,
              )
              .having((state) => state.dashboard, 'dashboard', dashboard)
              .having((state) => state.errorMessage, 'errorMessage', isNotNull),
        ]),
      );

      await cubit.load();
      await expectations;

      expect(cubit.state.dashboard, dashboard);
    });

    test('ignores the result of a load that finishes after close', () async {
      final harness = AnalyticsTestHarness();
      final gate = Completer<void>();
      harness.analyticsRepository.gate = gate;
      final cubit = AnalyticsCubit(harness.service);

      final load = cubit.load();
      await cubit.close();
      gate.complete();
      await load;

      expect(cubit.isClosed, isTrue);
    });

    test('swallows a failure that finishes after close', () async {
      final harness = AnalyticsTestHarness();
      final gate = Completer<void>();
      harness.analyticsRepository.gate = gate;
      harness.analyticsRepository.error = Exception('boom');
      final cubit = AnalyticsCubit(harness.service);

      final load = cubit.load();
      await cubit.close();
      gate.complete();
      await load;

      expect(cubit.isClosed, isTrue);
    });

    test('ignores load after close', () async {
      final harness = AnalyticsTestHarness();
      final cubit = AnalyticsCubit(harness.service);

      await cubit.close();
      await cubit.load();

      expect(harness.analyticsRepository.requestedRanges, isEmpty);
    });
  });
}
