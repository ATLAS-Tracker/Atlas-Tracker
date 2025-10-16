// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sp_fdc_food_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpFdcFoodDTO _$SpFdcFoodDTOFromJson(Map<String, dynamic> json) => SpFdcFoodDTO(
      fdcId: (json['fdc_id'] as num?)?.toInt(),
      descriptionEn: json['description_en'] as String?,
      descriptionDe: json['description_de'] as String?,
      descriptionFr: json['description_fr'] as String?,
      pictureUrl: json['picture_url'] as String?,
      nutrients: (json['fdc_nutrients'] as List<dynamic>)
          .map((e) => FDCFoodNutrimentDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      portion: json['fdc_portions'] == null
          ? null
          : SpFdcPortionDTO.fromJson(
              json['fdc_portions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpFdcFoodDTOToJson(SpFdcFoodDTO instance) =>
    <String, dynamic>{
      'fdc_id': instance.fdcId,
      'description_en': instance.descriptionEn,
      'description_de': instance.descriptionDe,
      'description_fr': instance.descriptionFr,
      'fdc_nutrients': instance.nutrients,
      'fdc_portions': instance.portion,
      'picture_url': instance.pictureUrl,
    };
