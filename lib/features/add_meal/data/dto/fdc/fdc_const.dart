class FDCConst {
  // URL
  static const fdcWebsiteUrl = "https://ciqual.anses.fr/#";
  static const _fdcFoodDetailPath = "/aliments/";
  static const _fdcBaseUrl = "api.nal.usda.gov";
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
