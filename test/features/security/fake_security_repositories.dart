import 'dart:async';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_account_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_category_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_transaction_repository.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:finecho/features/security/data/biometrics/biometric_authenticator.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';

/// An in-memory [SecurityRepository] fake for security tests.
class FakeSecurityRepository implements SecurityRepository {
  /// Creates a fake repository with an optional initial state.
  new({SecurityState? initialState}) : _state = initialState;

  SecurityState? _state;

  /// Every state passed to [update], in persistence order.
  final List<SecurityState> updates = <SecurityState>[];

  /// Error thrown by the next [get] call.
  Exception? getError;

  /// Error thrown by the next [update] call.
  Exception? updateError;

  /// Blocks [get] until completed, when provided.
  Completer<void>? getGate;

  SecurityState? get state => _state;

  @override
  Future<SecurityState?> get() async {
    final error = getError;
    if (error != null) {
      throw error;
    }
    final gate = getGate;
    if (gate != null) {
      await gate.future;
    }
    return _state;
  }

  @override
  Future<void> update(SecurityState newState) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updates.add(newState);
    _state = newState;
  }
}

/// A deterministic [SecurityCredentialRepository] fake that stores only a
/// salted verifier derived with the production [SecurityPinHasher].
///
/// The verifier is derived with the real PBKDF2-HMAC-SHA256 implementation,
/// so a regression that replaces the production derivation with a plaintext
/// comparison fails these tests instead of silently passing them. The fake
/// keeps only the error and gate hooks that model platform storage failures.
///
/// The derivation runs in the foreground at a single iteration so widget
/// tests can exercise the verifier without a background isolate, which
/// cannot complete inside a fake async test zone.
class FakeSecurityCredentialRepository implements SecurityCredentialRepository {
  String? _salt;
  String? _hash;

  /// Errors to throw from the next [savePin] call.
  Exception? saveError;

  /// Errors to throw from the next [verifyPin] call.
  Exception? verifyError;

  /// Error thrown by the next [hasPin] call.
  Exception? hasPinError;

  /// Error thrown by the next [clear] call.
  Exception? clearError;

  /// Error thrown by the next [acknowledgeUnreadableLegacyData] call.
  Exception? acknowledgeError;

  /// Blocks [clear] until completed, when provided.
  Completer<void>? clearGate;

  /// Blocks [savePin] until completed, when provided.
  Completer<void>? saveGate;

  /// Every PIN supplied to [verifyPin].
  final List<String> verifiedPins = <String>[];

  /// Every PIN supplied to [savePin].
  final List<String> savedPins = <String>[];

  /// Blocks [verifyPin] until completed, when provided.
  Completer<void>? verifyGate;

  /// Whether the store still holds data this build cannot read.
  bool legacyDataUnreadable = false;

  /// Error thrown by the next [hasUnreadableLegacyData] call.
  ///
  /// The real store raises when it cannot prove that its entries are
  /// readable, so the fake can model that case.
  Error? unreadableDataError;

  /// Whether the unreadable legacy data was acknowledged.
  bool legacyDataAcknowledged = false;

  @override
  Future<bool> hasUnreadableLegacyData() async {
    final error = unreadableDataError;
    if (error != null) {
      throw error;
    }
    return legacyDataUnreadable;
  }

  @override
  Future<void> acknowledgeUnreadableLegacyData() async {
    final error = acknowledgeError;
    if (error != null) {
      throw error;
    }
    legacyDataAcknowledged = true;
    legacyDataUnreadable = false;
  }

  @override
  Future<bool> hasPin() async {
    final error = hasPinError;
    if (error != null) {
      throw error;
    }
    return _hash != null;
  }

  @override
  Future<void> savePin(String pin) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    final gate = saveGate;
    if (gate != null) {
      await gate.future;
    }
    _salt = SecurityPinHasher.createSalt();
    _hash = SecurityPinHasher.hash(pin, _salt!, iterations: 1);
    savedPins.add(pin);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final error = verifyError;
    if (error != null) {
      throw error;
    }
    final gate = verifyGate;
    if (gate != null) {
      await gate.future;
    }
    verifiedPins.add(pin);
    final salt = _salt;
    final hash = _hash;
    if (salt == null || hash == null) {
      return false;
    }
    return SecurityPinHasher.matches(
      pin: pin,
      salt: salt,
      expectedHash: hash,
      iterations: 1,
    );
  }

  @override
  Future<void> clear() async {
    final error = clearError;
    if (error != null) {
      throw error;
    }
    final gate = clearGate;
    if (gate != null) {
      await gate.future;
    }
    _salt = null;
    _hash = null;
  }
}

/// A deterministic [BiometricAuthenticator] fake for security tests.
class FakeBiometricAuthenticator implements BiometricAuthenticator {
  /// Whether the device reports an enrolled biometric.
  bool available = false;

  /// The result reported by the next [authenticate] call.
  bool authenticateResult = true;

  /// The number of times the platform prompt ran.
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls++;
    return authenticateResult;
  }
}

/// A bundle of security fakes and the service built from them.
class SecurityTestHarness {
  /// Creates the fake repository bundle and its deterministic service.
  new({SecurityState? initialState, DateTime Function()? now})
    : securityRepository = FakeSecurityRepository(initialState: initialState),
      credentialRepository = FakeSecurityCredentialRepository(),
      transactionRepository = InMemoryTransactionRepository(),
      accountRepository = InMemoryAccountRepository(),
      categoryRepository = InMemoryCategoryRepository(),
      budgetRepository = InMemoryBudgetRepository() {
    service = SecurityService(
      repository: securityRepository,
      credentials: credentialRepository,
      transactionRepository: transactionRepository,
      accountRepository: accountRepository,
      categoryRepository: categoryRepository,
      budgetRepository: budgetRepository,
      now: now,
    );
  }

  /// The fake store for non-secret security metadata.
  final FakeSecurityRepository securityRepository;

  /// The fake PIN verifier store.
  final FakeSecurityCredentialRepository credentialRepository;

  /// The in-memory transaction store erased by a reset.
  final InMemoryTransactionRepository transactionRepository;

  /// The in-memory account store erased by a reset.
  final InMemoryAccountRepository accountRepository;

  /// The in-memory category store erased by a reset.
  final InMemoryCategoryRepository categoryRepository;

  /// The in-memory budget store erased by a reset.
  final InMemoryBudgetRepository budgetRepository;

  /// The service under test, backed by the fakes.
  late final SecurityService service;
}
