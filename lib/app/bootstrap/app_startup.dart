import 'package:finecho/app/bootstrap/app_bootstrap.dart';
import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';

/// Builds the application widget with every dependency ready.
///
/// The persisted onboarding and app-lock state are loaded before the router
/// chooses its first route, so the first frame already shows the correct
/// screen.
Future<FinEchoApp> buildApp() async {
  await AppBootstrap.ensureInitialized();
  final appRouter = await startAppRouter();
  return FinEchoApp(router: appRouter.router);
}

/// Loads the persisted onboarding and app-lock state before the router
/// chooses its first route.
///
/// The onboarding snapshot decides which onboarding step the user resumes
/// from, and the app-lock state decides whether the first route is protected.
/// Both have to be readable before the first route is built.
Future<AppRouter> startAppRouter() async {
  await sl<OnboardingCubit>().load();
  await sl<SecurityCubit>().load();
  return sl<AppRouter>();
}
