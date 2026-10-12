import 'package:finecho/core/models/category.dart';

/// Persists and reads FinEcho categories.
abstract interface class CategoryRepository {
  /// Returns all categories.
  Future<List<Category>> list();

  /// Returns the category with [id], or `null` when it does not exist.
  Future<Category?> get(String id);

  /// Inserts [category].
  Future<void> create(Category category);

  /// Replaces the stored category with the same id as [category].
  Future<void> update(Category category);

  /// Deletes the category with [id].
  Future<void> delete(String id);
}
