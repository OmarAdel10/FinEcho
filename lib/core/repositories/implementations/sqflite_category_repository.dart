import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed category repository implementation.
class SqfliteCategoryRepository implements CategoryRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<Category>> list() async {
    final rows = await _database.query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<Category?> get(String id) async {
    final rows = await _database.query(
      'categories',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Category.fromMap(rows.first);
  }

  @override
  Future<void> create(Category category) async {
    await _database.insert('categories', category.toMap());
  }

  @override
  Future<void> update(Category category) async {
    await _database.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'categories',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
