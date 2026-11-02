import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository repository;
  late SearchProductsUseCase useCase;

  void stubOff(Future<List<MealEntity>> Function() answer) =>
      when(() => repository.getOFFProductsByString(any(),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'))).thenAnswer((_) => answer());

  void stubSupabase(Future<List<MealEntity>> Function() answer) =>
      when(() => repository.getSupabaseFDCFoodsByString(any(),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'))).thenAnswer((_) => answer());

  Future<SearchProductsPage> search() =>
      useCase.searchProductsPage(searchString: 'prince', page: 0, pageSize: 10);

  setUp(() {
    repository = MockProductsRepository();
    useCase = SearchProductsUseCase(repository);
  });

  test('keeps Supabase results when OFF fails', () async {
    stubOff(() => Future.error(503));
    stubSupabase(() async => [MealEntity.empty()]);

    expect((await search()).results, hasLength(1));
  });

  test('keeps OFF results when Supabase fails', () async {
    stubOff(() async => [MealEntity.empty(), MealEntity.empty()]);
    stubSupabase(() => Future.error(Exception('offline')));

    expect((await search()).results, hasLength(2));
  });

  test('throws only when every source fails', () async {
    stubOff(() => Future.error(503));
    stubSupabase(() => Future.error(Exception('offline')));

    expect(search(), throwsStateError);
  });
}
