// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/onboarding/fake_onboarding_repository.dart';
import 'features/security/fake_security_repositories.dart';

void main() {
  testWidgets('renders the initial home route', (tester) async {
    final repository = FakeOnboardingRepository();
    final onboardingCubit = OnboardingCubit(OnboardingService(repository));
    final securityHarness = SecurityTestHarness();
    final securityCubit = SecurityCubit(securityHarness.service);
    final appRouter = AppRouter(
      onboardingCubit: onboardingCubit,
      securityCubit: securityCubit,
    );
    final router = appRouter.router;

    await tester.pumpWidget(FinEchoApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FinEcho'), findsOneWidget);

    router.dispose();
    await onboardingCubit.close();
    await securityCubit.close();
  });
}
