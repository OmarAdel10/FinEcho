import 'dart:convert';

import 'package:finecho/core/models/sms_message.dart';
import 'package:finecho/core/models/sms_parsing_rule.dart';
import 'package:finecho/core/repositories/contracts/sms_ingestion_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed SMS ingestion repository implementation.
class SqfliteSmsIngestionRepository implements SmsIngestionRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<SmsMessage>> listMessages() async {
    final rows = await _database.query(
      'sms_messages',
      orderBy: 'received_at DESC',
    );
    return rows.map(_messageFromRow).toList();
  }

  @override
  Future<SmsMessage?> getMessage(String id) async {
    final rows = await _database.query(
      'sms_messages',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _messageFromRow(rows.first);
  }

  @override
  Future<SmsMessage?> getMessageByFingerprint(String fingerprint) async {
    final rows = await _database.query(
      'sms_messages',
      where: 'fingerprint = ?',
      whereArgs: <Object?>[fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _messageFromRow(rows.first);
  }

  @override
  Future<void> createMessage(SmsMessage message) async {
    await _database.insert('sms_messages', _messageToRow(message));
  }

  @override
  Future<void> updateMessage(SmsMessage message) async {
    await _database.update(
      'sms_messages',
      _messageToRow(message),
      where: 'id = ?',
      whereArgs: <Object?>[message.id],
    );
  }

  @override
  Future<void> deleteMessage(String id) async {
    await _database.delete(
      'sms_messages',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<List<SmsParsingRule>> listParsingRules(String accountId) async {
    final rows = await _database.query(
      'sms_parsing_rules',
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
      orderBy: 'enabled DESC, id',
    );
    return rows.map(SmsParsingRule.fromMap).toList();
  }

  @override
  Future<SmsParsingRule?> getParsingRule(String id) async {
    final rows = await _database.query(
      'sms_parsing_rules',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SmsParsingRule.fromMap(rows.first);
  }

  @override
  Future<void> createParsingRule(SmsParsingRule rule) async {
    await _database.insert('sms_parsing_rules', rule.toMap());
  }

  @override
  Future<void> updateParsingRule(SmsParsingRule rule) async {
    await _database.update(
      'sms_parsing_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[rule.id],
    );
  }

  @override
  Future<void> deleteParsingRule(String id) async {
    await _database.delete(
      'sms_parsing_rules',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  static Map<String, Object?> _messageToRow(SmsMessage message) {
    final row = message.toMap();
    row['parsed_payload'] = _encodeParsedPayload(message.parsedPayload);
    return row;
  }

  static SmsMessage _messageFromRow(Map<String, Object?> row) {
    return SmsMessage.fromMap(<String, Object?>{
      ...row,
      'parsed_payload': _decodeParsedPayload(row['parsed_payload'] as String?),
    });
  }

  static String? _encodeParsedPayload(Map<String, Object?>? payload) {
    if (payload == null) {
      return null;
    }
    return jsonEncode(payload);
  }

  static Map<String, Object?>? _decodeParsedPayload(String? payload) {
    if (payload == null) {
      return null;
    }
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return null;
    }
    return Map<String, Object?>.from(decoded);
  }
}
