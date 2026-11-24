import 'package:finecho/app/environment/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvironmentConfig.fromBuildMode', () {
    test('resolves release builds to production', () {
      final config = EnvironmentConfig.fromBuildMode(isReleaseMode: true);

      expect(config.environment, Environment.production);
      expect(config.isProduction, isTrue);
      expect(config.shouldShowBadge, isFalse);
    });

    test('resolves debug and profile builds to development', () {
      final config = EnvironmentConfig.fromBuildMode(isReleaseMode: false);

      expect(config.environment, Environment.development);
      expect(config.isProduction, isFalse);
      expect(config.shouldShowBadge, isTrue);
    });
  });

  test('explicit constructor keeps the supplied environment', () {
    const config = EnvironmentConfig(Environment.development);

    expect(config.environment, Environment.development);
    expect(config.isProduction, isFalse);
  });
}
