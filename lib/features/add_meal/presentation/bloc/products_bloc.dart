import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'products_event.dart';

part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final log = Logger('ProductsBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  static const int _pageSize = 10;

  String _searchString = "";
  final List<MealEntity> _allResults = [];
  int _currentPage = -1;
  bool _hasMoreRemote = true;
  bool _isFetchingPage = false;
  int _visibleCount = 0;
  bool _usesImperialUnits = false;

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      final shouldReload =
          event.searchString != _searchString || state is! ProductsLoadedState;
      if (!shouldReload) return;
      _searchString = event.searchString;
      await _fetchPage(reset: true, emit: emit);
    });
    on<ClearProductsEvent>((event, emit) {
      if (state is ProductsInitial && _searchString.isEmpty) {
        return;
      }
      _resetPagination();
      _searchString = "";
      _usesImperialUnits = false;
      _isFetchingPage = false;
      emit(ProductsInitial());
    });
    on<LoadMoreProductsEvent>((event, emit) async {
      if (state is! ProductsLoadedState) {
        return;
      }
      if (_visibleCount < _allResults.length) {
        _visibleCount =
            math.min(_visibleCount + _pageSize, _allResults.length);
        _emitLoadedState(emit);
        return;
      }
      if (!_hasMoreRemote) {
        return;
      }
      await _fetchPage(reset: false, emit: emit, increaseVisibleCount: true);
    });
    on<RefreshProductsEvent>((event, emit) async {
      if (_searchString.isEmpty && state is! ProductsLoadedState) {
        return;
      }
      await _fetchPage(reset: true, emit: emit);
    });
  }

  Future<void> _fetchPage({
    required bool reset,
    required Emitter<ProductsState> emit,
    bool increaseVisibleCount = false,
  }) async {
    if (_isFetchingPage) {
      return;
    }
    if (!reset && !_hasMoreRemote && !increaseVisibleCount) {
      return;
    }

    _isFetchingPage = true;
    try {
      final requestSearch = _searchString;
      if (reset) {
        _resetPagination();
        emit(ProductsLoadingState());
        _usesImperialUnits =
            (await _getConfigUsecase.getConfig()).usesImperialUnits;
      } else {
        _emitLoadedState(emit, isLoadingMore: true);
      }

      final nextPage = reset ? 0 : _currentPage + 1;
      final searchResult = await _searchProductUseCase.searchProductsPage(
        searchString: requestSearch,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (requestSearch != _searchString) {
        return;
      }

      _currentPage = nextPage;
      _hasMoreRemote = searchResult.hasMore;
      _appendResults(searchResult.results);

      if (reset) {
        _visibleCount = math.min(_pageSize, _allResults.length);
      } else if (increaseVisibleCount) {
        _visibleCount =
            math.min(_visibleCount + _pageSize, _allResults.length);
      } else if (_visibleCount == 0) {
        _visibleCount = math.min(_pageSize, _allResults.length);
      }

      _emitLoadedState(emit);
    } catch (error, stackTrace) {
      log.severe('Failed to load products', error, stackTrace);
      if (reset) {
        emit(ProductsFailedState());
      } else {
        _emitLoadedState(emit);
      }
    } finally {
      _isFetchingPage = false;
    }
  }

  void _resetPagination() {
    _currentPage = -1;
    _hasMoreRemote = true;
    _visibleCount = 0;
    _allResults.clear();
  }

  void _appendResults(List<MealEntity> newResults) {
    if (newResults.isEmpty) {
      return;
    }
    final Map<String, MealEntity> resultMap = {
      for (final meal in _allResults) _mealKey(meal): meal,
    };

    for (final meal in newResults) {
      resultMap[_mealKey(meal)] = meal;
    }

    _allResults
      ..clear()
      ..addAll(resultMap.values);

    _sortResults(_allResults);
  }

  void _emitLoadedState(Emitter<ProductsState> emit,
      {bool isLoadingMore = false}) {
    emit(ProductsLoadedState(
      products: List<MealEntity>.unmodifiable(_allResults),
      usesImperialUnits: _usesImperialUnits,
      visibleCount: _visibleCount,
      hasMore: _hasMoreRemote || _visibleCount < _allResults.length,
      isLoadingMore: isLoadingMore,
    ));
  }

  String _mealKey(MealEntity meal) =>
      '${meal.source.name}:${meal.code ?? meal.name ?? ''}';

  List<MealEntity> _sortResults(List<MealEntity> results) {
    int score(MealEntity meal) {
      final name = (meal.name ?? '').toLowerCase();
      final query = _searchString.toLowerCase();
      if (name == query) return 0;
      if (name.startsWith(query)) return 1;
      if (name.contains(query)) return 2;
      return 3;
    }

    results.sort((a, b) {
      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa - sb;
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    return results;
  }
}
