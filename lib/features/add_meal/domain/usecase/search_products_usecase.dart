import 'dart:async';

import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
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
  static const Duration _offTimeout = Duration(seconds: 20);

  Future<List<MealEntity>> searchOFFProductsByString(String searchString,
      {int page = 1, int pageSize = 20}) async {
    final products = await _productsRepository.getOFFProductsByString(
      searchString,
      page: page,
      pageSize: pageSize,
    );
    return products;
  }

  Future<List<MealEntity>> searchFDCFoodByString(String searchString,
      {int pageNumber = 1, int pageSize = FDCConst.defaultPageSize}) async {
    final foods = await _productsRepository.getFDCFoodsByString(
      searchString,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    return foods;
  }

  Future<List<MealEntity>> searchSupabaseFDCFoodsByString(String searchString,
      {int page = 0, int pageSize = SPConst.maxNumberOfItems}) async {
    final foods = await _productsRepository.getSupabaseFDCFoodsByString(
      searchString,
      page: page,
      pageSize: pageSize,
    );
    return foods;
  }

  Future<SearchProductsPage> searchProductsPage({
    required String searchString,
    required int page,
    required int pageSize,
  }) async {
    final offFuture = _productsRepository
        .getOFFProductsByString(
          searchString,
          page: page + 1,
          pageSize: pageSize,
        )
        .timeout(_offTimeout, onTimeout: () => const <MealEntity>[])
        .catchError((error, stackTrace) {
          if (error is TimeoutException) {
            return const <MealEntity>[];
          }
          Error.throwWithStackTrace(error, stackTrace);
        });

    final fdcFuture = _productsRepository.getFDCFoodsByString(
      searchString,
      pageNumber: page + 1,
      pageSize: pageSize,
    );

    final supabaseFuture =
        _productsRepository.getSupabaseFDCFoodsByString(
      searchString,
      page: page,
      pageSize: pageSize,
    );

    final results = await Future.wait<List<MealEntity>>([
      offFuture,
      fdcFuture,
      supabaseFuture,
    ]);

    final offResults = results[0];
    final fdcResults = results[1];
    final supabaseResults = results[2];

    final combined = [...offResults, ...fdcResults, ...supabaseResults];
    final hasMore = offResults.length == pageSize ||
        fdcResults.length == pageSize ||
        supabaseResults.length == pageSize;

    return SearchProductsPage(results: combined, hasMore: hasMore);
  }
}
