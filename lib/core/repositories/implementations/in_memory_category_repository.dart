import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';

/// An in-memory [CategoryRepository] implementation for development and tests
/// until the encrypted database wiring task lands.
class InMemoryCategoryRepository implements CategoryRepository {
  /// Creates an in-memory category repository with optional initial categories.
  new({Map<String, Category> initialCategories = const <String, Category>{}})
    : _categories = Map.of(initialCategories);

  final Map<String, Category> _categories;

  @override
  Future<List<Category>> list() async => _categories.values.toList();

  @override
  Future<Category?> get(String id) async => _categories[id];

  @override
  Future<void> create(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> update(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> delete(String id) async {
    _categories.remove(id);
  }
}
