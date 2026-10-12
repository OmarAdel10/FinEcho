import 'package:finecho/app/environment/environment.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:get_it/get_it.dart';

/// The application service locator.
final GetIt sl = GetIt.instance;

/// Registers the initial application-wide dependencies.
Future<void> configureDependencies({
  Environment environment = Environment.development,
}) async {
  sl
    ..registerSingleton<EnvironmentConfig>(EnvironmentConfig(environment))
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
