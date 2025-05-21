// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipesDBOAdapter extends TypeAdapter<RecipesDBO> {
  @override
  final int typeId = 17;

  @override
  RecipesDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipesDBO(
      recipe: fields[0] as MealDBO,
      ingredients: (fields[1] as List).cast<IntakeForRecipeDBO>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecipesDBO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.recipe)
      ..writeByte(1)
      ..write(obj.ingredients);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipesDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipesDBO _$RecipesDBOFromJson(Map<String, dynamic> json) => RecipesDBO(
      recipe: MealDBO.fromJson(json['recipe'] as Map<String, dynamic>),
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IntakeForRecipeDBO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecipesDBOToJson(RecipesDBO instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'ingredients': instance.ingredients,
    };
