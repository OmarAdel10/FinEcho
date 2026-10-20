import 'dart:async';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';

/// An in-memory [SecurityRepository] fake for security tests.
class FakeSecurityRepository implements SecurityRepository {
  /// Creates a fake repository with an optional initial state.
  new({SecurityState? initialState}) : _state = initialState;

  SecurityState? _state;

  /// Every state passed to [update], in persistence order.
  final List<SecurityState> updates = <SecurityState>[];

  SecurityState? get state => _state;

  @override
  Future<SecurityState?> get() async => _state;

  @override
  Future<void> update(SecurityState newState) async {
    updates.add(newState);
    _state = newState;
  }
}

/// A deterministic, in-memory [SecurityCredentialRepository] fake.
class FakeSecurityCredentialRepository implements SecurityCredentialRepository {
  String? _pin;

  /// Errors to throw from the next [savePin] call.
  Exception? saveError;

  /// Errors to throw from the next [verifyPin] call.
  Exception? verifyError;

  /// Every PIN supplied to [verifyPin].
  final List<String> verifiedPins = <String>[];

  /// Blocks [verifyPin] until completed, when provided.
  Completer<void>? verifyGate;

  @override
  Future<bool> hasPin() async => _pin != null;

  @override
  Future<void> savePin(String pin) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }
    _pin = pin;
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
    return pin == _pin;
  }

  @override
  Future<void> clear() async {
    _pin = null;
  }
}

/// A bundle of security fakes and the service built from them.
class SecurityTestHarness {
  /// Creates the fake repository bundle and its deterministic service.
  new({SecurityState? initialState, DateTime Function()? now})
    : securityRepository = FakeSecurityRepository(initialState: initialState),
      credentialRepository = FakeSecurityCredentialRepository() {
    service = SecurityService(
      repository: securityRepository,
      credentials: credentialRepository,
      now: now,
    );
  }

  /// The fake store for non-secret security metadata.
  final FakeSecurityRepository securityRepository;

  /// The fake PIN verifier store.
  final FakeSecurityCredentialRepository credentialRepository;

  /// The service under test, backed by the fakes.
  late final SecurityService service;
}
