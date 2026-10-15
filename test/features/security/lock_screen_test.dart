import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import 'fake_security_repositories.dart';

void main() {
  Future<SecurityCubit> createCubit(SecurityTestHarness harness) async {
    await harness.credentialRepository.savePin('123456');
    final cubit = SecurityCubit(harness.service);
    await cubit.load();
    return cubit;
  }

  Widget wrapScreen(SecurityCubit cubit, TextEditingController pinController) {
    return MaterialApp(
      home: BlocProvider<SecurityCubit>.value(
        value: cubit,
        child: LockScreen(pinController: pinController),
      ),
    );
  }

  group('LockScreen', () {
    testWidgets('reports a wrong PIN and keeps the lock message', (
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
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '000000');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(harness.securityRepository.state?.failedUnlockAttempts, 1);
      await cubit.close();
    });

    testWidgets('unlocks with the configured PIN', (tester) async {
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
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(find.text('Incorrect PIN. Try again.'), findsNothing);
      expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);
      await cubit.close();
    });
  });
}
