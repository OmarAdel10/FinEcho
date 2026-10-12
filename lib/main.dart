import 'package:finecho/app/bootstrap/app_bootstrap.dart';
import 'package:finecho/app/bootstrap/fin_echo_app.dart';
import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await AppBootstrap.ensureInitialized();
  final router = sl<AppRouter>().router;
  runApp(FinEchoApp(router: router));
}
