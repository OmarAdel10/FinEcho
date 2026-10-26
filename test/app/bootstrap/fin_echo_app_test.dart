import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/security/view/widgets/security_lifecycle_observer.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/fake_analytics_repositories.dart';
import '../../features/security/fake_security_repositories.dart';

void main() {
  testWidgets('watches the app lifecycle at the application scope', (
    tester,
  ) async {
    final cubit = await _unlockedCubit();
    final analyticsCubit = await _readyAnalyticsCubit();
    final router = _router();
    addTearDown(router.dispose);
    addTearDown(cubit.close);
    addTearDown(analyticsCubit.close);

    await tester.pumpWidget(
      FinEchoApp(
        router: router,
        securityCubit: cubit,
        analyticsCubit: analyticsCubit,
      ),
    );
    await tester.pump();

    expect(find.byType(SecurityLifecycleObserver), findsOneWidget);
  });

  testWidgets('relocks the app when the application is paused', (tester) async {
    final cubit = await _unlockedCubit();
    final analyticsCubit = await _readyAnalyticsCubit();
    final router = _router();
    addTearDown(router.dispose);
    addTearDown(cubit.close);
    addTearDown(analyticsCubit.close);
    expect(cubit.state.isLocked, isFalse);

    await tester.pumpWidget(
      FinEchoApp(
        router: router,
        securityCubit: cubit,
        analyticsCubit: analyticsCubit,
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.ready);
    expect(cubit.state.isLocked, isTrue);
  });

  testWidgets('clears cached analytics when the application is paused', (
    tester,
  ) async {
    final securityCubit = await _unlockedCubit();
    final analyticsHarness = AnalyticsTestHarness();
    final analyticsCubit = AnalyticsCubit(analyticsHarness.service);
    await analyticsCubit.load();
    addTearDown(securityCubit.close);
    addTearDown(analyticsCubit.close);
    expect(analyticsCubit.state.dashboard, isNotNull);

    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      FinEchoApp(
        router: router,
        securityCubit: securityCubit,
        analyticsCubit: analyticsCubit,
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(analyticsCubit.state.dashboard, isNull);
    expect(analyticsCubit.state.period, AnalyticsPeriod.month);
  });

  testWidgets('keeps cached analytics when pausing without a configured lock', (
    tester,
  ) async {
    final securityCubit = await _unconfiguredCubit();
    final analyticsHarness = AnalyticsTestHarness();
    final analyticsCubit = AnalyticsCubit(analyticsHarness.service);
    await analyticsCubit.load();
    addTearDown(securityCubit.close);
    addTearDown(analyticsCubit.close);
    expect(analyticsCubit.state.dashboard, isNotNull);

    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      FinEchoApp(
        router: router,
        securityCubit: securityCubit,
        analyticsCubit: analyticsCubit,
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(securityCubit.state.isLocked, isFalse);
    expect(analyticsCubit.state.dashboard, isNotNull);
    expect(analyticsCubit.state.period, AnalyticsPeriod.month);
  });

  testWidgets('keeps cached analytics when only the analytics cubit is wired', (
    tester,
  ) async {
    final analyticsHarness = AnalyticsTestHarness();
    final analyticsCubit = AnalyticsCubit(analyticsHarness.service);
    await analyticsCubit.load();
    addTearDown(analyticsCubit.close);
    expect(analyticsCubit.state.dashboard, isNotNull);

    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      FinEchoApp(router: router, analyticsCubit: analyticsCubit),
    );
    await tester.pump();

    expect(find.byType(SecurityLifecycleObserver), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(analyticsCubit.state.dashboard, isNotNull);
  });

  testWidgets('fails to wire the app lock without the analytics cubit', (
    tester,
  ) async {
    final cubit = await _unlockedCubit();
    final router = _router();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    expect(
      () => FinEchoApp(router: router, securityCubit: cubit),
      throwsA(isA<AssertionError>()),
    );
  });
}

Future<AnalyticsCubit> _readyAnalyticsCubit() async {
  final harness = AnalyticsTestHarness();
  final cubit = AnalyticsCubit(harness.service);
  await cubit.load();
  return cubit;
}

Future<SecurityCubit> _unlockedCubit() async {
  final harness = SecurityTestHarness(
    initialState: SecurityState(
      appLockEnabled: true,
      pinConfigured: true,
      failedUnlockAttempts: 0,
      secureKeyReady: true,
      updatedAt: DateTime.utc(2026, 10, 15, 12),
    ),
    now: () => DateTime.utc(2026, 10, 15, 12),
  );
  await harness.credentialRepository.savePin('123456');
  final cubit = SecurityCubit(harness.service);
  await cubit.load();
  await cubit.unlockWithPin('123456');
  return cubit;
}

Future<SecurityCubit> _unconfiguredCubit() async {
  final harness = SecurityTestHarness(
    initialState: SecurityState(
      appLockEnabled: false,
      pinConfigured: false,
      failedUnlockAttempts: 0,
      secureKeyReady: true,
      updatedAt: DateTime.utc(2026, 10, 15, 12),
    ),
    now: () => DateTime.utc(2026, 10, 15, 12),
  );
  final cubit = SecurityCubit(harness.service);
  await cubit.load();
  return cubit;
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('App')),
      ),
    ],
  );
}
