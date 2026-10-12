import 'package:finecho/core/models/sms_message.dart';
import 'package:finecho/core/models/sms_parsing_rule.dart';

/// Persists Android SMS events and their parsing rules.
abstract interface class SmsIngestionRepository {
  /// Returns all SMS messages, most recently received first.
  Future<List<SmsMessage>> listMessages();

  /// Returns the SMS message with [id], or `null` when it does not exist.
  Future<SmsMessage?> getMessage(String id);

  /// Returns the SMS message with [fingerprint], or `null` when absent.
  Future<SmsMessage?> getMessageByFingerprint(String fingerprint);

  /// Inserts [message].
  Future<void> createMessage(SmsMessage message);

  /// Replaces the stored SMS message with the same id as [message].
  Future<void> updateMessage(SmsMessage message);

  /// Deletes the SMS message with [id].
  Future<void> deleteMessage(String id);

  /// Returns all parsing rules for [accountId].
  Future<List<SmsParsingRule>> listParsingRules(String accountId);

  /// Returns the parsing rule with [id], or `null` when it does not exist.
  Future<SmsParsingRule?> getParsingRule(String id);

  /// Inserts [rule].
  Future<void> createParsingRule(SmsParsingRule rule);

  /// Replaces the stored parsing rule with the same id as [rule].
  Future<void> updateParsingRule(SmsParsingRule rule);

  /// Deletes the parsing rule with [id].
  Future<void> deleteParsingRule(String id);
}
