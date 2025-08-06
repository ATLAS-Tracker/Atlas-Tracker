import 'dart:io';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_fdc_food_dto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpFdcDataSource {
  final log = Logger('SPBackendDataSource');

  Future<List<SpFdcFoodDTO>> fetchSearchWordResults(String searchString) async {
    try {
      log.fine('Fetching Supabase FDC results');
      final supaBaseClient = locator<SupabaseClient>();
      final queryDescriptionColumn = SPConst.getFdcFoodDescriptionColumnName(
        SupportedLanguage.fromCode(Platform.localeName),
      );

      final response = await supaBaseClient
          .from(SPConst.fdcFoodTableName)
          .select(
            '''${SPConst.fdcFoodPictureUrl}, $queryDescriptionColumn, ${SPConst.fdcFoodPictureUrl}, fdc_portions (  ${SPConst.fdcPortionsMeasureUnitId}, ${SPConst.fdcPortionsAmount}, ${SPConst.fdcPortionsGramWeight} ), fdc_nutrients ( ${SPConst.fdcNutrientId}, ${SPConst.fdcNutrientsAmount} )''',
          )
          .textSearch(
            queryDescriptionColumn,
            searchString,
            type: TextSearchType.websearch,
          )
          .limit(SPConst.maxNumberOfItems);

      final fdcFoodItems = response
          .map((fdcFood) => SpFdcFoodDTO.fromJson(fdcFood))
          .toList();

      log.fine('Successful response from Supabase');
      return fdcFoodItems;
    } catch (exception, stacktrace) {
      log.severe('Exception while getting FDC word search $exception');
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);
      return Future.error(exception);
    }
  }
}
