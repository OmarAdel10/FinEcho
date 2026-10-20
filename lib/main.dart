import 'package:finecho/app/bootstrap/app_bootstrap.dart';
import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await AppBootstrap.ensureInitialized(useSecureStorage: true);
  await sl<SecurityCubit>().load();
  final router = sl<AppRouter>().router;
  runApp(FinEchoApp(router: router));
}
