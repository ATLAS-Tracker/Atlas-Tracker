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
  final int visibleCount;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductsLoadedState(
      {required this.products,
      required this.visibleCount,
      this.hasMore = false,
      this.isLoadingMore = false});

  ProductsLoadedState copyWith({
    List<MealEntity>? products,
    int? visibleCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductsLoadedState(
      products: products ?? this.products,
      visibleCount: visibleCount ?? this.visibleCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [products, visibleCount, hasMore, isLoadingMore];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
