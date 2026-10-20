import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';

/// Loads the persisted app lock before the router chooses its first route.
Future<AppRouter> startAppRouter() async {
  await sl<SecurityCubit>().load();
  return sl<AppRouter>();
}
