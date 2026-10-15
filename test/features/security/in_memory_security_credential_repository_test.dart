import 'package:finecho/features/security/data/repositories/in_memory_security_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemorySecurityCredentialRepository', () {
    test('reports no PIN before one is configured', () async {
      final repository = InMemorySecurityCredentialRepository();

      expect(await repository.hasPin(), isFalse);
      expect(await repository.verifyPin('123456'), isFalse);
    });

    test('verifies the configured PIN without exposing it', () async {
      final repository = InMemorySecurityCredentialRepository();

      await repository.savePin('123456');

      expect(await repository.hasPin(), isTrue);
      expect(await repository.verifyPin('000000'), isFalse);
      expect(await repository.verifyPin('123456'), isTrue);
    });

    test('replaces the previous PIN verifier', () async {
      final repository = InMemorySecurityCredentialRepository();

      await repository.savePin('123456');
      await repository.savePin('654321');

      expect(await repository.verifyPin('123456'), isFalse);
      expect(await repository.verifyPin('654321'), isTrue);
    });

    test('clears the PIN verifier', () async {
      final repository = InMemorySecurityCredentialRepository();

      await repository.savePin('123456');
      await repository.clear();

      expect(await repository.hasPin(), isFalse);
      expect(await repository.verifyPin('123456'), isFalse);
    });
  });
}
