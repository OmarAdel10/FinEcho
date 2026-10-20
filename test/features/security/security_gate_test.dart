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
    await cubit.close();
  });
}
