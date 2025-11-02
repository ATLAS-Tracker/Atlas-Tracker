part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductsEvent {
  final String searchString;

  const LoadProductsEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class ClearProductsEvent extends ProductsEvent {
  const ClearProductsEvent();
}

class LoadMoreProductsEvent extends ProductsEvent {
  const LoadMoreProductsEvent();
}

class RefreshProductsEvent extends ProductsEvent {
  const RefreshProductsEvent();

  @override
  List<Object?> get props => [];
}
