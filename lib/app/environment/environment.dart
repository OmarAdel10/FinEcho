/// The build environments supported by FinEcho.
/// The build environments supported by FinEcho.
enum Environment {
  /// Local development build.
  development,

  /// Staging build that mirrors production behavior.
  staging,

  /// Production release build.
  production,
}

/// Immutable configuration derived from the active build environment.
class EnvironmentConfig {
  /// Creates an environment configuration.
  const new(this.environment);

  /// The active environment.
  final Environment environment;

  /// Whether the current build is a production build.
  bool get isProduction => environment == Environment.production;

  /// Whether a non-production badge should be visible.
  bool get shouldShowBadge => !isProduction;
}
