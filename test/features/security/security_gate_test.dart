import 'dart:async';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view/widgets/security_gate.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import 'fake_security_repositories.dart';

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

  testWidgets('resets app lock after confirmation', (tester) async {
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
    await tester.tap(find.text('Erase app data'));
    await tester.pumpAndSettle();
    expect(find.text('Erase app data?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app data'));
    await tester.pumpAndSettle();

    expect(find.text('Security settings unavailable'), findsNothing);
    expect(find.text('Protected content'), findsOneWidget);
    expect(await harness.credentialRepository.hasPin(), isFalse);
  });

  testWidgets('hides protected content while erasing app data', (tester) async {
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

    await tester.tap(find.text('Erase app data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app data'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Protected content'), findsNothing);

    clearGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Protected content'), findsOneWidget);
  });

  testWidgets('keeps the recovery screen when erasing app data fails', (
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

    await tester.tap(find.text('Erase app data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Erase app data'));
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

  testWidgets('keeps app lock when erasing app data is cancelled', (
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

    await tester.tap(find.text('Erase app data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Security settings unavailable'), findsOneWidget);
    expect(await harness.credentialRepository.hasPin(), isTrue);
    expect(harness.securityRepository.state, isNull);
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
