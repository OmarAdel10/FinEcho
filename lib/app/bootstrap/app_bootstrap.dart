import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/environment/environment.dart';

/// Prepares the application before `runApp`.
abstract final class AppBootstrap {
  /// Initializes bindings and registers application-wide dependencies.
  static Future<void> ensureInitialized({
    Environment environment = Environment.development,
    bool useSecureStorage = false,
  }) async {
    await configureDependencies(
      environment: environment,
      useSecureStorage: useSecureStorage,
    );
  }
}
