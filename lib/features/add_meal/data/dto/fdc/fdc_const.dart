class FDCConst {
  static const int defaultPageSize = 20;

  // URL
  static const fdcWebsiteUrl = "https://ciqual.anses.fr/#";
  static const _fdcFoodDetailPath = "/aliments/";
  static const _fdcBaseUrl = "api.nal.usda.gov";
  static const _fdcFoodSearchPath = "/fdc/v1/foods/search";

  static const _fdcQueryTag = "query";
  static const _fdcPageSizeTag = "pageSize";
  static const _fdcPageNumberTag = "pageNumber";
  static const _fdcDataTypeTag = "dataType";

  // static const _fdcDataTypeBrandedValue = "Branded";
  static const _fdcDataTypeFoundationValue = "Foundation";
  static const _fdcDataTypeSRLegacyValue = "SR Legacy";
  static const _fdcSortOrderTag = "sortOrder";
  static const _fdcSortOrderAscValue = "asc";
  static const _fdcApiKeyTag = "api_key";

  static const _dataTypeParams = [
    _fdcDataTypeFoundationValue,
    _fdcDataTypeSRLegacyValue
  ];

  static const fdcDefaultUnit = 'g';

  static const Map<int, String> measureUnits = {
    1000: "tasse",
    1001: "cuillère à soupe",
    1002: "cuillère à café",
    1003: "litre",
    1004: "miliLitre",
    1006: "centimètre cube", // 1 cm^3 = 1 ml
    9999: "portion",
  };

  static String getFoodDetailUrlString(String? code) {
    if (code == null) {
      return _fdcBaseUrl;
    } else {
      return fdcWebsiteUrl + _fdcFoodDetailPath + code;
    }
  }

  static String _getDataTypeParams() => _dataTypeParams.join(",");

  static Uri getFDCWordSearchUrl(String searchString, String apiKey,
      {int pageNumber = 1, int pageSize = defaultPageSize}) {
    final queryParameters = {
      _fdcQueryTag: searchString,
      _fdcPageSizeTag: pageSize.toString(),
      _fdcDataTypeTag: _getDataTypeParams(),
      _fdcSortOrderTag: _fdcSortOrderAscValue,
      _fdcApiKeyTag: apiKey,
      _fdcPageNumberTag: pageNumber.toString(),
    };

    return Uri.https(_fdcBaseUrl, _fdcFoodSearchPath, queryParameters);
  }

  // Nutriment codes
  static const fdcTotalKcalId = 1008;
  static const fdcKcalAtwaterGeneralId = 957;
  static const fdcKcalAtwaterSpecificId = 958;
  static const fdcTotalCarbsId = 1005;
  static const fdcTotalFatId = 1004;
  static const fdcTotalProteinsId = 1003;
  static const fdcTotalSugarId = 1063;
  static const fdcTotalSaturatedFatId = 1258;
  static const fdcTotalDietaryFiberId = 1079;

  // Measure unit codes
  static const fdcPortionServingId = 1049;
  static const fdcPortionUnknownId = 9999;
}
