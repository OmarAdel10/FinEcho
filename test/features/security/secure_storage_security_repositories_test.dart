import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  group('SecurityPinHasher', () {
    test('matches only the PIN hashed with the same salt', () {
      final salt = SecurityPinHasher.createSalt();
      final hash = SecurityPinHasher.hash('123456', salt);

      expect(
        SecurityPinHasher.matches(
          pin: '123456',
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );
      expect(
        SecurityPinHasher.matches(
          pin: '654321',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
      expect(
        SecurityPinHasher.matches(
          pin: '123456',
          salt: SecurityPinHasher.createSalt(),
          expectedHash: hash,
        ),
        isFalse,
      );
    });
  });

  group('SecureStorageSecurityRepository', () {
    test('returns null before any state is persisted', () async {
      final repository = SecureStorageSecurityRepository(
        store: _InMemorySecureKeyValueStore(),
      );

      expect(await repository.get(), isNull);
    });

    test('restores every persisted security field', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);
      final state = SecurityState(
        appLockEnabled: true,
        pinConfigured: true,
        failedUnlockAttempts: 3,
        lockedUntil: DateTime.utc(2026, 10, 15, 12, 1),
        secureKeyReady: true,
        updatedAt: DateTime.utc(2026, 10, 15, 12),
      );

      await repository.update(state);

      expect(store.values, contains(SecureStorageSecurityRepository.stateKey));
      expect(await repository.get(), state);
    });
  });

  group('SecureStorageSecurityCredentialRepository', () {
    test(
      'saves and verifies a salted PIN without storing it plainly',
      () async {
        final store = _InMemorySecureKeyValueStore();
        final repository = SecureStorageSecurityCredentialRepository(
          store: store,
        );

        await repository.savePin('123456');

        final persisted = store.values.values.single;
        expect(persisted, isNot(contains('123456')));
        expect(await repository.hasPin(), isTrue);
        expect(await repository.verifyPin('123456'), isTrue);
        expect(await repository.verifyPin('654321'), isFalse);
      },
    );

    test('uses a fresh salt for every saved PIN', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );

      await repository.savePin('123456');
      final first = store.values.values.single;
      await repository.savePin('123456');
      final second = store.values.values.single;

      expect(second, isNot(first));
      expect(await repository.verifyPin('123456'), isTrue);
    });

    test('clears the stored verifier', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );
      await repository.savePin('123456');

      await repository.clear();

      expect(store.values, isEmpty);
      expect(await repository.hasPin(), isFalse);
      expect(await repository.verifyPin('123456'), isFalse);
    });
  });
}
