import 'dart:async';

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class SearchProductsPage {
  final List<MealEntity> results;
  final bool hasMore;

  const SearchProductsPage({required this.results, required this.hasMore});
}

class SearchProductsUseCase {
  final ProductsRepository _productsRepository;

  SearchProductsUseCase(this._productsRepository);
  static final _log = Logger('SearchProductsUseCase');
  static const Duration _offTimeout = Duration(seconds: 10);
  // OFF hits are ranked locally: a wide page lets the products matching every
  // typed word reach the top (50 ranked as well as 100 in field tests).
  static const _offPageSize = 50;

  /// Searches OFF (branded products) and Supabase (generic foods). A failing
  /// source only drops its own results; throws only when both fail.
  Future<SearchProductsPage> searchProductsPage({
    required String searchString,
    required int page,
    required int pageSize,
  }) async {
    var failures = 0;
    Future<List<MealEntity>> orEmpty(Future<List<MealEntity>> request) =>
        request.catchError((Object error) {
          failures++;
          _log.warning('Product search source failed', error);
          return const <MealEntity>[];
        });

    final [off, supabase] = await Future.wait<List<MealEntity>>([
      orEmpty(_productsRepository
          .getOFFProductsByString(searchString,
              page: page + 1, pageSize: _offPageSize)
          .timeout(_offTimeout)),
      orEmpty(_productsRepository.getSupabaseFDCFoodsByString(searchString,
          page: page, pageSize: pageSize)),
    ]);
    if (failures == 2) {
      throw StateError('All product search sources failed');
    }

    return SearchProductsPage(
      results: [...off, ...supabase],
      hasMore: off.length >= _offPageSize || supabase.length == pageSize,
    );
  }
}
