import 'package:finecho/core/models/speech_draft.dart';

/// Persists and reads FinEcho speech entry drafts.
abstract interface class SpeechRepository {
  /// Returns all speech drafts, most recently changed first.
  Future<List<SpeechDraft>> list();

  /// Returns the speech draft with [id], or `null` when it does not exist.
  Future<SpeechDraft?> get(String id);

  /// Inserts [draft].
  Future<void> create(SpeechDraft draft);

  /// Replaces the stored speech draft with the same id as [draft].
  Future<void> update(SpeechDraft draft);

  /// Deletes the speech draft with [id].
  Future<void> delete(String id);
}
