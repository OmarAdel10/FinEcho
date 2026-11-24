/// The build environments supported by FinEcho.
///
/// The environment is a function of the compiled build mode: `debug` and
/// `profile` builds behave as development, `release` builds as production.
enum Environment {
  /// Non-release build (`debug` or `profile`).
  development,

  /// Release build.
  production,
}

/// Immutable configuration derived from the active build environment.
class EnvironmentConfig {
  /// Creates an environment configuration.
  const new(this.environment);

  /// Resolves the environment from the compiled build mode.
  factory fromBuildMode({required bool isReleaseMode}) {
    return EnvironmentConfig(
      isReleaseMode ? Environment.production : Environment.development,
    );
  }

  /// The active environment.
  final Environment environment;

  /// Whether the current build is a production build.
  bool get isProduction => environment == Environment.production;

  /// Whether a non-production badge should be visible.
  bool get shouldShowBadge => !isProduction;
}
