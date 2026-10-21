import 'dart:async';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view/widgets/security_gate.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'fake_security_repositories.dart';

/// A cubit that can emit a load failure without a user-facing message.
class _ErrorOnlySecurityCubit(super.service) extends SecurityCubit {
  /// Emits an error state that carries no explanation.
  void failWithoutMessage() {
    emit(
      SecurityAccessState(
        securityState: state.securityState,
        status: SecurityAccessStatus.error,
      ),
    );
  }
}

void main() {
  testWidgets('locks, unlocks, and relocks when the app pauses', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.unlocked);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('Protected content'), findsOneWidget);
    expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.ready);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.unlocked);
    expect(find.text('Protected content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  testWidgets('loads security state when the gate mounts', (tester) async {
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
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('shows a recoverable error when security state cannot load', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Security settings unavailable'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Security settings unavailable'), findsNothing);
    expect(find.text('Protected content'), findsOneWidget);
  });

  testWidgets('resets the app lock after confirmation', (tester) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Security settings unavailable'), findsOneWidget);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    expect(find.text('Erase app lock?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app lock'));
    await tester.pumpAndSettle();

    expect(find.text('Security settings unavailable'), findsNothing);
    expect(find.text('Protected content'), findsOneWidget);
    expect(await harness.credentialRepository.hasPin(), isFalse);
  });

  testWidgets('hides protected content while erasing the app lock', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    harness.securityRepository.getError = null;
    final clearGate = Completer<void>();
    harness.credentialRepository.clearGate = clearGate;

    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app lock'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);

    clearGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Protected content'), findsOneWidget);
  });

  testWidgets('keeps the recovery screen when erasing the app lock fails', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    harness.securityRepository.getError = null;
    harness.securityRepository.updateError = Exception('keystore write');
    harness.credentialRepository.clearError = Exception('keystore delete');

    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app lock'));
    await tester.pumpAndSettle();

    expect(find.text('Security settings unavailable'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
    expect(
      find.text(
        'Could not reset app lock. Clear FinEcho app data from system settings '
        'and relaunch.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps app lock when erasing the app lock is cancelled', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    harness.securityRepository.getError = null;

    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Security settings unavailable'), findsOneWidget);
    expect(await harness.credentialRepository.hasPin(), isTrue);
    expect(harness.securityRepository.state, isNull);
  });

  testWidgets('routes to welcome after erasing the app lock', (tester) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);
    final router = _routerWithGate(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(find.text('Security settings unavailable'), findsOneWidget);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app lock'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FinEcho'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('returns to setup when a retry finds no configured lock', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);
    final router = _routerWithGate(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(find.text('Security settings unavailable'), findsOneWidget);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FinEcho'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('keeps the route when a retry finds a configured lock', (
    tester,
  ) async {
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
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);
    final router = _routerWithGate(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(find.text('Security settings unavailable'), findsOneWidget);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unlock FinEcho'), findsOneWidget);
    expect(find.text('Welcome to FinEcho'), findsNothing);
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('returns to setup when an erase reload fails and a retry works', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    await harness.credentialRepository.savePin('123456');
    harness.securityRepository.getError = const FormatException('corrupt');
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);
    final router = _routerWithGate(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump();
    expect(find.text('Security settings unavailable'), findsOneWidget);

    await tester.tap(find.text('Erase app lock'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app lock'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not reload app lock settings. Tap Try again.'),
      findsOneWidget,
    );
    expect(find.text('Protected content'), findsNothing);

    harness.securityRepository.getError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FinEcho'), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('keeps the opened route when a normal start finds no lock', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    final cubit = SecurityCubit(harness.service);
    addTearDown(cubit.close);
    final router = _routerWithGate(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(cubit.state.status, SecurityAccessStatus.unlocked);
    expect(find.text('Protected content'), findsOneWidget);
    expect(find.text('Welcome to FinEcho'), findsNothing);
  });

  testWidgets('shows a generic message when the failure has no details', (
    tester,
  ) async {
    final harness = SecurityTestHarness(
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    final cubit = _ErrorOnlySecurityCubit(harness.service);
    addTearDown(cubit.close);
    cubit.failWithoutMessage();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Could not load security settings. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Protected content'), findsNothing);
  });

  testWidgets('removes its lifecycle observer when disposed', (tester) async {
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
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    expect(cubit.state.status, SecurityAccessStatus.unlocked);

    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.unlocked);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}

/// Builds a router that gates the protected area and exposes the setup route.
GoRouter _routerWithGate(SecurityCubit cubit) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const SecurityGate(child: Text('Protected content')),
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Text('Welcome to FinEcho'),
      ),
    ],
  );
}
