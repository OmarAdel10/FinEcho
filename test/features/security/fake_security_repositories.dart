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

/// A deterministic, in-memory [SecurityCredentialRepository] fake.
class FakeSecurityCredentialRepository implements SecurityCredentialRepository {
  String? _pin;

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
    return _pin != null;
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
    _pin = pin;
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
    return pin == _pin;
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
