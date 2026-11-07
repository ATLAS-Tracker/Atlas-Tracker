import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class MockSearch extends Mock implements SearchProductByBarcodeUseCase {}

void main() {
  test('repeated camera detections trigger only one lookup while pending',
      () async {
    final search = MockSearch();
    final pending = Completer<MealEntity>();
    when(() => search.searchProductByBarcode('123'))
        .thenAnswer((_) => pending.future);
    final bloc = ScannerBloc(search);
    bloc.add(const ScannerLoadProductEvent(barcode: '123'));
    bloc.add(const ScannerLoadProductEvent(barcode: '123'));
    await Future<void>.delayed(Duration.zero);
    verify(() => search.searchProductByBarcode('123')).called(1);
    final loaded =
        bloc.stream.firstWhere((state) => state is ScannerLoadedState);
    pending.complete(MealEntity.empty());
    await loaded;
    await bloc.close();
  });
  test('missing product offers the missing-product state', () async {
    final search = MockSearch();
    when(() => search.searchProductByBarcode('missing'))
        .thenThrow(ProductNotFoundException());
    final bloc = ScannerBloc(search);
    final failed =
        bloc.stream.firstWhere((state) => state is ScannerFailedState);
    bloc.add(const ScannerLoadProductEvent(barcode: 'missing'));
    expect((await failed as ScannerFailedState).type,
        ScannerFailedStateType.productNotFound);
    await bloc.close();
  });
  test('scanner can retry after an error without a second loading flag',
      () async {
    final search = MockSearch();
    when(() => search.searchProductByBarcode('123'))
        .thenThrow(StateError('offline'));
    final bloc = ScannerBloc(search);
    final failed =
        bloc.stream.firstWhere((state) => state is ScannerFailedState);
    bloc.add(const ScannerLoadProductEvent(barcode: '123'));
    await failed;
    when(() => search.searchProductByBarcode('123'))
        .thenAnswer((_) async => MealEntity.empty());
    final loaded =
        bloc.stream.firstWhere((state) => state is ScannerLoadedState);
    bloc.add(const ScannerLoadProductEvent(barcode: '123'));
    await loaded;
    verify(() => search.searchProductByBarcode('123')).called(2);
    await bloc.close();
  });
}
