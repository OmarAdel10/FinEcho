import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed category repository implementation.
class SqfliteCategoryRepository implements CategoryRepository {
  /// Creates a repository that opens the encrypted database that stores the
  /// categories for every call.
  const new({required this.opener});

  /// Opens the encrypted database that stores the categories.
  final Future<Database> Function() opener;

  @override
  Future<List<Category>> list() async {
    final database = await opener();
    final rows = await database.query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<Category?> get(String id) async {
    final database = await opener();
    final rows = await database.query(
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
    final database = await opener();
    await database.insert('categories', category.toMap());
  }

  @override
  Future<void> update(Category category) async {
    final database = await opener();
    await database.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await opener();
    await database.delete(
      'categories',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    final database = await opener();
    await database.delete('categories');
  }
}
