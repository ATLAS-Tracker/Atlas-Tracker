import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class ProductsRepository {
  final OFFDataSource _offDataSource;
  final FDCDataSource _fdcDataSource;
  final SpFdcDataSource _spBackendDataSource;

  ProductsRepository(
      this._offDataSource, this._fdcDataSource, this._spBackendDataSource);

  Future<List<MealEntity>> getOFFProductsByString(String searchString,
      {int page = 1, int pageSize = 20}) async {
    final offWordResponse = await _offDataSource.fetchSearchWordResults(
      searchString,
      page: page,
      pageSize: pageSize,
    );

    final products = offWordResponse.products
        .map((offProduct) => MealEntity.fromOFFProduct(offProduct))
        .toList();

    return products;
  }

  Future<List<MealEntity>> getFDCFoodsByString(String searchString,
      {int pageNumber = 1, int pageSize = FDCConst.defaultPageSize}) async {
    final fdcWordResponse = await _fdcDataSource.fetchSearchWordResults(
      searchString,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    final products = fdcWordResponse.foods
        .map((food) => MealEntity.fromFDCFood(food))
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
