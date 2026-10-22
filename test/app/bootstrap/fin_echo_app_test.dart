import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/widgets/security_lifecycle_observer.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/security/fake_security_repositories.dart';

void main() {
  testWidgets('watches the app lifecycle at the application scope', (
    tester,
  ) async {
    final cubit = await _unlockedCubit();
    final router = _router();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(FinEchoApp(router: router, securityCubit: cubit));
    await tester.pump();

    expect(find.byType(SecurityLifecycleObserver), findsOneWidget);
  });

  testWidgets('relocks the app when the application is paused', (tester) async {
    final cubit = await _unlockedCubit();
    final router = _router();
    addTearDown(router.dispose);
    addTearDown(cubit.close);
    expect(cubit.state.isLocked, isFalse);

    await tester.pumpWidget(FinEchoApp(router: router, securityCubit: cubit));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(cubit.state.status, SecurityAccessStatus.ready);
    expect(cubit.state.isLocked, isTrue);
  });
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
