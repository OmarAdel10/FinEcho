import 'dart:async';
import 'dart:convert';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/data/models/pin_verifier.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/secure_storage_security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A salt with the persisted shape: sixteen random bytes in base64url.
final String _testSalt = base64UrlEncode(List<int>.generate(16, (i) => i));

/// A verifier with the persisted shape: thirty-two bytes in base64url.
final String _testHash = base64UrlEncode(List<int>.generate(32, (i) => i));

class _RecordingFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = <String, String>{};

  /// The upgrade status the fake reports to the app.
  SecureStorageUpgradeStatus upgradeStatus = const SecureStorageUpgradeStatus(
    state: SecureStorageUpgradeState.ok,
  );

  /// The error the fake raises when the upgrade check runs.
  Exception? checkError;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  Future<SecureStorageUpgradeStatus> checkUpgradeStatus({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final error = checkError;
    if (error != null) {
      throw error;
    }
    return upgradeStatus;
  }
}

class _InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  /// The keys the store was asked to read, in order.
  final List<String> reads = <String>[];

  /// Whether the store reports data written by an earlier backend.
  bool legacyDataUnreadable = false;

  @override
  Future<String?> read(String key) async {
    reads.add(key);
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<bool> hasUnreadableLegacyData() async => legacyDataUnreadable;
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

    test('creates fresh 16-byte salts and deterministic hashes', () {
      final first = SecurityPinHasher.createSalt();
      final second = SecurityPinHasher.createSalt();

      expect(base64Url.decode(first), hasLength(16));
      expect(second, isNot(first));
      expect(
        SecurityPinHasher.hash('123456', first),
        SecurityPinHasher.hash('123456', first),
      );
      expect(
        SecurityPinHasher.hash('123456', first),
        isNot(SecurityPinHasher.hash('123456', second)),
      );
      expect(
        SecurityPinHasher.matches(
          pin: '123456',
          salt: first,
          expectedHash: 'short',
        ),
        isFalse,
      );
    });

    test('derives the standard PBKDF2-HMAC-SHA256 verifier', () {
      // RFC 8018 vector for PBKDF2-HMAC-SHA256, dkLen 32.
      expect(
        SecurityPinHasher.hash('123456', 'testsalt', iterations: 1000),
        'mpS8LaEuQLbijkmKysBh4SJ-u9C9YTk4xHSfty-f3A0=',
      );
      expect(
        SecurityPinHasher.matches(
          pin: '123456',
          salt: 'testsalt',
          expectedHash: 'mpS8LaEuQLbijkmKysBh4SJ-u9C9YTk4xHSfty-f3A0=',
          iterations: 1000,
        ),
        isTrue,
      );
    });

    test('separates verifiers derived with different iteration counts', () {
      final salt = SecurityPinHasher.createSalt();
      final cheap = SecurityPinHasher.hash('123456', salt, iterations: 1000);
      final costly = SecurityPinHasher.hash('123456', salt, iterations: 2000);

      expect(cheap, isNot(costly));
      expect(
        SecurityPinHasher.matches(
          pin: '123456',
          salt: salt,
          expectedHash: costly,
          iterations: 1000,
        ),
        isFalse,
      );
    });

    test('verifies the legacy single-round verifier', () {
      expect(
        SecurityPinHasher.legacyHash('123456', 'testsalt'),
        '6Gd-FGoB6pAYGIQA9rQ76K1OFUbd0kZwUO8MFQgC2HM=',
      );
      expect(
        SecurityPinHasher.matchesLegacy(
          pin: '123456',
          salt: 'testsalt',
          expectedHash: '6Gd-FGoB6pAYGIQA9rQ76K1OFUbd0kZwUO8MFQgC2HM=',
        ),
        isTrue,
      );
      expect(
        SecurityPinHasher.matchesLegacy(
          pin: '654321',
          salt: 'testsalt',
          expectedHash: '6Gd-FGoB6pAYGIQA9rQ76K1OFUbd0kZwUO8MFQgC2HM=',
        ),
        isFalse,
      );
    });

    test('derives the verifier on a background isolate', () async {
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => ticks++,
      );
      addTearDown(timer.cancel);

      final derived = await SecurityPinHasher.hashInBackground(
        '123456',
        'testsalt',
      );

      expect(derived, SecurityPinHasher.hash('123456', 'testsalt'));
      // The calling isolate kept running while the derivation ran, so the
      // expensive work did not block the platform isolate.
      expect(ticks, greaterThan(0));
    });

    test('verifies a PIN on a background isolate', () async {
      final salt = SecurityPinHasher.createSalt();
      final hash = SecurityPinHasher.hash('123456', salt);

      expect(
        await SecurityPinHasher.matchesInBackground(
          pin: '123456',
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );
      expect(
        await SecurityPinHasher.matchesInBackground(
          pin: '654321',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
    });

    test('verifies a legacy PIN with the legacy derivation', () {
      const salt = 'testsalt';
      final hash = SecurityPinHasher.legacyHash('123456', salt);

      expect(
        SecurityPinHasher.matchesLegacy(
          pin: '123456',
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );
      expect(
        SecurityPinHasher.matchesLegacy(
          pin: '654321',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
    });
  });

  group('PinVerifier', () {
    test(
      'creates a verifier with the current format and derivation cost',
      () async {
        final verifier = await PinVerifier.create('123456');

        expect(verifier.version, PinVerifier.currentVersion);
        expect(PinVerifier.currentVersion, 2);
        expect(PinVerifier.legacyVersion, 1);
        expect(PinVerifier.minIterations, 10000);
        expect(PinVerifier.maxIterations, 200000);
        expect(SecurityPinHasher.defaultIterations, 100000);
        expect(verifier.iterations, SecurityPinHasher.defaultIterations);
        expect(base64Url.decode(verifier.salt), hasLength(16));
        expect(await verifier.matches('123456'), isTrue);
        expect(await verifier.matches('654321'), isFalse);
      },
    );

    test('round-trips a verifier through its encoded payload', () async {
      final verifier = await PinVerifier.create('123456');

      final decoded = PinVerifier.decode(verifier.encode());

      expect(decoded.salt, verifier.salt);
      expect(decoded.hash, verifier.hash);
      expect(decoded.iterations, verifier.iterations);
      expect(decoded.version, verifier.version);
      expect(await decoded.matches('123456'), isTrue);
    });

    test('verifies a legacy verifier with the legacy derivation', () async {
      final legacy = PinVerifier(
        salt: 'testsalt',
        hash: SecurityPinHasher.legacyHash('123456', 'testsalt'),
      );

      expect(await legacy.matches('123456'), isTrue);
      expect(await legacy.matches('654321'), isFalse);
      final created = await PinVerifier.create('123456');
      expect(await created.matches('123456'), isTrue);
    });

    test('verifies a PIN with the persisted iteration count', () async {
      const iterations = 10000;
      final verifier = PinVerifier(
        salt: _testSalt,
        hash: SecurityPinHasher.hash(
          '123456',
          _testSalt,
          iterations: iterations,
        ),
        iterations: iterations,
        version: PinVerifier.currentVersion,
      );

      expect(await verifier.matches('123456'), isTrue);
      expect(await verifier.matches('654321'), isFalse);
    });

    test('accepts a payload at the derivation ceiling', () {
      final decoded = PinVerifier.decode(
        '{"salt": "$_testSalt", "hash": "$_testHash", "version": 2, '
        '"iterations": ${PinVerifier.maxIterations}}',
      );

      expect(decoded.iterations, PinVerifier.maxIterations);
    });

    test('rejects payloads that are not verifiers', () {
      expect(() => PinVerifier.decode('[]'), throwsFormatException);
      expect(() => PinVerifier.decode('{}'), throwsFormatException);
      expect(
        () => PinVerifier.decode('{"salt": 1, "hash": "$_testHash"}'),
        throwsFormatException,
      );
    });

    test('rejects a salt or hash that is not the persisted shape', () {
      expect(
        () => PinVerifier.decode('{"salt": "c2hvcnQ", "hash": "$_testHash"}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Malformed persisted PIN verifier.',
          ),
        ),
      );
      expect(
        () => PinVerifier.decode('{"salt": "$_testSalt", "hash": "c2hvcnQ="}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Malformed persisted PIN verifier.',
          ),
        ),
      );
    });

    test('rejects a corrupt version or iteration count', () {
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "version": "2"}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier version.',
          ),
        ),
      );
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "iterations": "100"}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier iterations.',
          ),
        ),
      );
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "iterations": 0}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier iterations.',
          ),
        ),
      );
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "version": 2, '
          '"iterations": ${PinVerifier.maxIterations + 1}}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier iterations.',
          ),
        ),
      );
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "version": 2, '
          '"iterations": ${PinVerifier.minIterations - 1}}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier iterations.',
          ),
        ),
      );
    });

    test('rejects a payload written before the first version', () {
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "version": 0}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier version.',
          ),
        ),
      );
    });

    test('rejects a current-format payload without an iteration count', () {
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", "version": 2}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier iterations.',
          ),
        ),
      );
    });

    test('rejects a payload written by a newer format', () {
      expect(
        () => PinVerifier.decode(
          '{"salt": "$_testSalt", "hash": "$_testHash", '
          '"version": ${PinVerifier.currentVersion + 1}}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted PIN verifier version.',
          ),
        ),
      );
    });

    test('accepts a payload that names the legacy version', () {
      final decoded = PinVerifier.decode(
        '{"salt": "$_testSalt", "hash": "$_testHash", "version": 1}',
      );

      expect(decoded.version, PinVerifier.legacyVersion);
      expect(decoded.iterations, 1);
    });
  });

  group('FlutterSecureKeyValueStore', () {
    test('forwards reads, writes, and deletes to platform storage', () async {
      final storage = _RecordingFlutterSecureStorage();
      final store = FlutterSecureKeyValueStore(storage: storage);

      expect(await store.read('key'), isNull);
      await store.write('key', 'value');
      expect(await store.read('key'), 'value');
      await store.delete('key');
      expect(await store.read('key'), isNull);
    });

    test('keeps a keystore error visible instead of erasing the lock', () {
      const store = FlutterSecureKeyValueStore();

      expect(store.storage.aOptions.toMap()['resetOnError'], 'false');
    });

    test(
      'reports data written by an earlier build that cannot be read',
      () async {
        final storage = _RecordingFlutterSecureStorage();
        final store = FlutterSecureKeyValueStore(storage: storage);

        expect(await store.hasUnreadableLegacyData(), isFalse);

        storage.upgradeStatus = const SecureStorageUpgradeStatus(
          state: SecureStorageUpgradeState.legacyDataUnreadable,
        );

        expect(await store.hasUnreadableLegacyData(), isTrue);

        storage.upgradeStatus = const SecureStorageUpgradeStatus(
          state: SecureStorageUpgradeState.legacyDataDiscarded,
        );

        expect(await store.hasUnreadableLegacyData(), isTrue);
      },
    );

    test('fails closed when the upgrade check cannot run', () async {
      final storage = _RecordingFlutterSecureStorage();
      final store = FlutterSecureKeyValueStore(storage: storage);
      storage.checkError = Exception('keystore unavailable');

      await expectLater(
        store.hasUnreadableLegacyData(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Secure storage upgrade check failed'),
          ),
        ),
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

    test('rejects malformed state payloads', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);

      store.values[SecureStorageSecurityRepository.stateKey] = '{';
      await expectLater(repository.get(), throwsFormatException);

      store.values[SecureStorageSecurityRepository.stateKey] = '[]';
      await expectLater(repository.get(), throwsFormatException);
    });

    test('writes a versioned payload', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);

      await repository.update(
        SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
      );

      final payload = jsonDecode(
        store.values[SecureStorageSecurityRepository.stateKey]!,
      ) as Map<String, dynamic>;
      expect(payload['version'], SecureStorageSecurityRepository.codecVersion);
      expect(payload['state'], isA<Map<String, dynamic>>());
    });

    test('rejects a payload with an unsupported version', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);
      store.values[SecureStorageSecurityRepository.stateKey] = jsonEncode({
        'version': SecureStorageSecurityRepository.codecVersion + 1,
        'state': <String, Object?>{},
      });

      await expectLater(repository.get(), throwsFormatException);
    });

    test('rejects a versioned payload without a state', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);
      store.values[SecureStorageSecurityRepository.stateKey] = jsonEncode({
        'version': SecureStorageSecurityRepository.codecVersion,
      });

      await expectLater(repository.get(), throwsFormatException);
    });

    test('reads a payload written before the codec was versioned', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityRepository(store: store);
      final state = SecurityState(
        appLockEnabled: true,
        pinConfigured: true,
        failedUnlockAttempts: 0,
        secureKeyReady: true,
        updatedAt: DateTime.utc(2026, 10, 15, 12),
      );
      store.values[SecureStorageSecurityRepository.stateKey] = jsonEncode(
        state.toMap(),
      );

      expect(await repository.get(), state);
    });

    test(
      'rejects a malformed payload written before the codec was versioned',
      () async {
        final store = _InMemorySecureKeyValueStore();
        final repository = SecureStorageSecurityRepository(store: store);
        store.values[SecureStorageSecurityRepository.stateKey] = jsonEncode({
          'id': 'not-a-number',
          'app_lock_enabled': 1,
          'pin_configured': 1,
          'failed_unlock_attempts': 0,
          'secure_key_ready': 1,
          'updated_at': 0,
        });

        await expectLater(repository.get(), throwsFormatException);
      },
    );
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

    test('rejects malformed verifier payloads', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );

      store.values[SecureStorageSecurityCredentialRepository.credentialKey] =
          '{';
      await expectLater(repository.hasPin(), throwsFormatException);
      await expectLater(repository.verifyPin('123456'), throwsFormatException);

      store.values[SecureStorageSecurityCredentialRepository.credentialKey] =
          '{"salt": 1, "hash": "value"}';
      await expectLater(repository.hasPin(), throwsFormatException);

      store.values[SecureStorageSecurityCredentialRepository.credentialKey] =
          '[]';
      await expectLater(repository.hasPin(), throwsFormatException);
    });

    test('verifies a verifier persisted in the legacy format', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );
      store.values[SecureStorageSecurityCredentialRepository.credentialKey] =
          jsonEncode({
            'salt': _testSalt,
            'hash': SecurityPinHasher.legacyHash('123456', _testSalt),
          });

      expect(await repository.hasPin(), isTrue);
      expect(await repository.verifyPin('123456'), isTrue);
      expect(await repository.verifyPin('654321'), isFalse);
    });

    test('reports unreadable legacy data until it is acknowledged', () async {
      final store = _InMemorySecureKeyValueStore()..legacyDataUnreadable = true;
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );

      expect(await repository.hasUnreadableLegacyData(), isTrue);

      await repository.acknowledgeUnreadableLegacyData();

      expect(await repository.hasUnreadableLegacyData(), isFalse);
      expect(
        store.values,
        contains(
          SecureStorageSecurityCredentialRepository.legacyAcknowledgedKey,
        ),
      );
    });

    test('checks the store before it reads the acknowledgement', () async {
      final store = _InMemorySecureKeyValueStore();
      final repository = SecureStorageSecurityCredentialRepository(
        store: store,
      );

      expect(await repository.hasUnreadableLegacyData(), isFalse);
      expect(store.reads, isEmpty);

      store.legacyDataUnreadable = true;

      expect(await repository.hasUnreadableLegacyData(), isTrue);
      expect(store.reads, <String>[
        SecureStorageSecurityCredentialRepository.legacyAcknowledgedKey,
      ]);
    });
  });
}
