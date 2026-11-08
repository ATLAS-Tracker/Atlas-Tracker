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
      updatedAt: fields[2] as DateTime?,
      portions: fields[3] == null ? 1 : fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RecipesDBO obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.recipe)
      ..writeByte(1)
      ..write(obj.ingredients)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.portions);
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
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      portions: (json['portions'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$RecipesDBOToJson(RecipesDBO instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'ingredients': instance.ingredients,
      'updated_at': instance.updatedAt.toIso8601String(),
      'portions': instance.portions,
    };
