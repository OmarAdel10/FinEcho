import 'package:finecho/app/di/service_locator.dart';
import 'package:flutter/widgets.dart';

/// Prepares the application before `runApp`.
abstract final class AppBootstrap {
  /// Initializes bindings and registers application-wide dependencies.
  ///
  /// Secure storage is the default. Tests opt into the in-memory graph
  /// explicitly.
  static Future<void> ensureInitialized({
    bool useInMemoryStorage = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies(useInMemoryStorage: useInMemoryStorage);
  }
}
