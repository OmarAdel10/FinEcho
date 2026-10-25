import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/widgets/security_lifecycle_observer.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_security_repositories.dart';

void main() {
  testWidgets('relocks the app when it is paused', (tester) async {
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
    expect(cubit.state.status, SecurityAccessStatus.unlocked);

    await tester.pumpWidget(
      SecurityLifecycleObserver(
        cubit: cubit,
        child: const MaterialApp(home: Text('App')),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.ready);
    expect(cubit.state.isLocked, isTrue);
  });

  testWidgets('runs the lock hook when it is paused', (tester) async {
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

    var lockHookCalls = 0;
    await tester.pumpWidget(
      SecurityLifecycleObserver(
        cubit: cubit,
        onLock: () => lockHookCalls++,
        child: const MaterialApp(home: Text('App')),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(lockHookCalls, 1);
  });

  testWidgets('stops relocking when the observer is disposed', (tester) async {
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
      SecurityLifecycleObserver(
        cubit: cubit,
        child: const MaterialApp(home: Text('App')),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.unlocked);
    expect(cubit.state.isLocked, isFalse);
  });

  testWidgets('keeps the app unlocked until it is paused', (tester) async {
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
      SecurityLifecycleObserver(
        cubit: cubit,
        child: const MaterialApp(home: Text('App')),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(cubit.state.isLocked, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(cubit.state.isLocked, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(cubit.state.isLocked, isTrue);
  });
}
