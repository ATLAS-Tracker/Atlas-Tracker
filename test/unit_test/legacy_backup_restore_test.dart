import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_or_recipe_dbo.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/sync/legacy_backup_restore.dart';

void main() {
  Uint8List zip(Map<String, Object> files) {
    final archive = Archive();
    files.forEach((name, rows) {
      final bytes = utf8.encode(jsonEncode(rows));
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Map<String, dynamic> intake(String id) => jsonDecode(jsonEncode(IntakeDBO(
        id: id,
        unit: 'g',
        amount: 150,
        type: IntakeTypeDBO.lunch,
        dateTime: DateTime(2026, 10, 30, 12),
        updatedAt: DateTime.utc(2026, 10, 30),
        meal: MealDBO(
          code: 'potato',
          name: 'Pommes de terre',
          brands: null,
          thumbnailImageUrl: null,
          mainImageUrl: null,
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: MealNutrimentsDBO(
            energyKcalPerQuantity: 87,
            carbohydratesPerQuantity: 20,
            fatPerQuantity: 0.1,
            proteinsPerQuantity: 1.9,
            sugarsPerQuantity: null,
            saturatedFatPerQuantity: null,
            fiberPerQuantity: null,
            mealOrRecipe: MealOrRecipeDBO.meal,
          ),
          source: MealSourceDBO.custom,
        ),
      ))) as Map<String, dynamic>;

  test('reads intakes from a logout backup, defaulting missing versions', () {
    final legacy = intake('b')..remove('updatedAt');
    final journal = parseLegacyBackup(zip({
      ExportImportBloc.userIntakeJsonFileName: [intake('a'), legacy],
    }));

    expect(journal.intakes.map((i) => i.id), ['a', 'b']);
    expect(journal.intakes.first.meal.name, 'Pommes de terre');
    expect(journal.intakes.last.updatedAt, DateTime(2026, 10, 30, 12));
    expect(journal.recipes, isEmpty);
  });
}
