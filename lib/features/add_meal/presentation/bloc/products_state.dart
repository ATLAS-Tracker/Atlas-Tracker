part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  @override
  List<Object> get props => [];
}

class ProductsLoadingState extends ProductsState {
  @override
  List<Object?> get props => [];
}

class ProductsLoadedState extends ProductsState {
  final List<MealEntity> products;
  final bool usesImperialUnits;
  final int visibleCount;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductsLoadedState(
      {required this.products,
      required this.visibleCount,
      this.usesImperialUnits = false,
      this.hasMore = false,
      this.isLoadingMore = false});

  ProductsLoadedState copyWith({
    List<MealEntity>? products,
    bool? usesImperialUnits,
    int? visibleCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductsLoadedState(
      products: products ?? this.products,
      visibleCount: visibleCount ?? this.visibleCount,
      usesImperialUnits: usesImperialUnits ?? this.usesImperialUnits,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [products, usesImperialUnits, visibleCount, hasMore, isLoadingMore];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
