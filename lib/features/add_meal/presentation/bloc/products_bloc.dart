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
  static const _searchDebounce = Duration(milliseconds: 400);

  String _searchString = "";
  final List<MealEntity> _allResults = [];
  int _currentPage = -1;
  bool _hasMoreRemote = true;
  bool _isFetchingPage = false;
  int _visibleCount = 0;
  bool _usesImperialUnits = false;
  String _pendingSearch = "";
  // Bumped on every fetch so responses of superseded requests are dropped.
  int _requestId = 0;

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      // Search is fired on every keystroke: only keep the last one.
      _pendingSearch = event.searchString;
      await Future.delayed(_searchDebounce);
      if (_pendingSearch != event.searchString) return;
      final shouldReload = event.searchString != _searchString ||
          state is ProductsFailedState;
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
      _pendingSearch = "";
      _requestId++;
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
    if (_isFetchingPage && !reset) {
      return;
    }
    if (!reset && !_hasMoreRemote && !increaseVisibleCount) {
      return;
    }

    final requestId = ++_requestId;
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

      if (requestId != _requestId || requestSearch != _searchString) {
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
      if (requestId != _requestId) return;
      if (reset) {
        emit(ProductsFailedState());
      } else {
        _emitLoadedState(emit);
      }
    } finally {
      if (requestId == _requestId) _isFetchingPage = false;
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

  /// Name matches first (exact, prefix, contains), generic foods before
  /// branded products, and otherwise the sources' own order (OFF: popularity).
  void _sortResults(List<MealEntity> results) {
    final query = _fold(_searchString);
    int rank(MealEntity meal) {
      final name = _fold(meal.name ?? '');
      final match = name == query
          ? 0
          : name.startsWith(query)
              ? 1
              : name.contains(query)
                  ? 2
                  : 3;
      return match * 2 + (meal.source == MealSourceEntity.off ? 1 : 0);
    }

    // List.sort is not stable: keep the arrival index as tie-break.
    final ranked = [for (final (i, meal) in results.indexed) (rank(meal), i, meal)];
    ranked.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    results
      ..clear()
      ..addAll(ranked.map((r) => r.$3));
  }

  /// Lowercase without French accents, so "pate" ranks "Pâte" as a match.
  static String _fold(String text) {
    var folded = text.toLowerCase().trim().replaceAll('œ', 'oe');
    for (final (accented, plain) in _accents) {
      folded = folded.replaceAll(RegExp('[$accented]'), plain);
    }
    return folded;
  }

  static const _accents = [
    ('àâä', 'a'),
    ('éèêë', 'e'),
    ('îï', 'i'),
    ('ôö', 'o'),
    ('ùûü', 'u'),
    ('ç', 'c'),
  ];
}
