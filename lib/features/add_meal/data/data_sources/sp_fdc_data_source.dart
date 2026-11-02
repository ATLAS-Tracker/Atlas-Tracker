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

  Future<List<SpFdcFoodDTO>> fetchSearchWordResults(String searchString,
      {int offset = 0, int limit = SPConst.maxNumberOfItems}) async {
    try {
      log.fine('Fetching Supabase FDC results');
      final supaBaseClient = locator<SupabaseClient>();
      final language = SupportedLanguage.fromCode(Platform.localeName);
      final queryDescriptionColumn =
          SPConst.getFdcFoodDescriptionColumnName(language);

      // search_fdc_food (supabase/fdc_food_search.sql) ignores accents and
      // tolerates typos, unlike the plain full-text search.
      final query = supaBaseClient
          .rpc(SPConst.fdcFoodSearchFunctionName, params: {
            'search': searchString,
            'lang': language.name,
          })
          .select(
              '''${SPConst.fdcFoodId}, $queryDescriptionColumn, fdc_portions (  ${SPConst.fdcPortionsMeasureUnitId}, ${SPConst.fdcPortionsAmount}, ${SPConst.fdcPortionsGramWeight} ), fdc_nutrients ( ${SPConst.fdcNutrientId}, ${SPConst.fdcNutrientsAmount} )''');

      if (limit <= 0) {
        return [];
      }
      final toIndex = offset + limit - 1;
      final response = await query.range(offset, toIndex);

      final fdcFoodItems =
          response.map((fdcFood) => SpFdcFoodDTO.fromJson(fdcFood)).toList();

      log.fine('Successful response from Supabase');
      return fdcFoodItems;
    } catch (exception, stacktrace) {
      log.severe('Exception while getting FDC word search $exception');
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);
      return Future.error(exception);
    }
  }
}
