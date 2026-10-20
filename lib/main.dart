import 'package:finecho/app/bootstrap/app_bootstrap.dart';
import 'package:finecho/app/bootstrap/app_startup.dart';
import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await AppBootstrap.ensureInitialized(useSecureStorage: true);
  final appRouter = await startAppRouter();
  runApp(FinEchoApp(router: appRouter.router));
}
