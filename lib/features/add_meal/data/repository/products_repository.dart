import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class ProductsRepository {
  final OFFDataSource _offDataSource;
  final SpFdcDataSource _spBackendDataSource;

  ProductsRepository(this._offDataSource, this._spBackendDataSource);

  Future<List<MealEntity>> getOFFProductsByString(String searchString,
      {int page = 1, int pageSize = 20}) async {
    final offProducts = await _offDataSource.fetchSearchWordResults(
      searchString,
      page: page,
      pageSize: pageSize,
    );

    final products = offProducts
        .map((offProduct) => MealEntity.fromOFFProduct(offProduct))
        .where((mealEntity) => mealEntity.hasNutriments)
        .toList();

    return products;
  }

  Future<List<MealEntity>> getSupabaseFDCFoodsByString(String searchString,
      {int page = 0, int pageSize = SPConst.maxNumberOfItems}) async {
    final offset = page * pageSize;
    final spFdcWordResponse = await _spBackendDataSource.fetchSearchWordResults(
      searchString,
      offset: offset,
      limit: pageSize,
    );
    final products = spFdcWordResponse
        .map((foodItem) => MealEntity.fromSpFDCFood(foodItem))
        .toList();
    return products;
  }

  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    final productResponse = await _offDataSource.fetchBarcodeResults(barcode);

    return MealEntity.fromOFFProduct(productResponse.product);
  }
}
