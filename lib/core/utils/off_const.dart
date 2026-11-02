class OFFConst {
  static const offWebsiteUrl = "https://world.openfoodfacts.org/";
  static const _offBaseUrl = "world.openfoodfacts.org";
  // search-a-licious: the legacy /cgi/search.pl is rate limited and mostly
  // answers 503.
  static const _offSearchBaseUrl = "search.openfoodfacts.org";
  static const _offSearchTag = "/search";
  static const _offProductSearchTag = "/api/v2/product";

  static const offHttpSuccessCode = 200;
  static const offHttpDownCodes = [502, 503, 500];
  static const offProductNotFoundCode = 404;

  static const _offSearchQueryTag = "q";
  static const _offSearchLangsTag = "langs";
  static const _offSearchCountryFilter = 'countries_tags:"en:france"';
  // Drops sparse entries (no photo, no category...) that clutter results.
  static const _offSearchCompletenessFilter = 'completeness:[0.4 TO *]';
  static const _offSearchSortTag = "sort_by";
  // Most scanned first: the real LU "Prince" before obscure lookalikes.
  static const _offSearchSortByPopularity = "-unique_scans_n";
  // Lucene operators in user input would break or alter the query.
  static final _offSearchSyntaxChars = RegExp(r'[+\-!(){}\[\]^"~*?:\\/&|]');
  static const _offFieldsTag = "fields";
  static const _offJsonTag = "json";
  static const _offJsonValue = "true";

  static const _offProductNameTag = "product_name";
  static const _offProductNameENTag = "product_name_en";
  static const _offProductNameDETag = "product_name_de";
  static const _offProductNameFRTag = "product_name_fr";
  static const _offCodeTag = "code";
  static const _offBrandsTag = "brands";

  static const _offUrlTag = "url";
  static const _offImageUrlTag = "image_url";
  static const _offImageThumbUrlTag = "image_front_thumb_url";
  static const _offImageFrontUrlTag = "image_front_url";
  // static const _offImageNutritionUrlTag = "image_nutrition_url";
  // static const _offImageIngredientsUrlTag = "image_ingredients_url";

  static const _offProductQuantityTag = "product_quantity";
  static const _offQuantityTag = "quantity";
  static const _offServingQuantityTag = "serving_quantity";
  static const _offServingSizeTag = "serving_size";
  static const _offNutrimentsTag = "nutriments";

  static const _returnFields = [
    _offCodeTag,
    _offBrandsTag,
    _offProductNameTag,
    _offProductNameENTag,
    _offProductNameDETag,
    _offProductNameFRTag,
    _offUrlTag,
    _offImageUrlTag,
    _offImageThumbUrlTag,
    _offImageFrontUrlTag,
    _offProductQuantityTag,
    _offQuantityTag,
    _offServingQuantityTag,
    _offServingSizeTag,
    _offNutrimentsTag
  ];

  static String _getReturnFields() => _returnFields.join(",");

  static const _offPageSizeTag = "page_size";
  static const _offPageTag = "page";

  static Uri getOffWordSearchUrl(String searchString,
      {int page = 1, int pageSize = 20}) {
    final terms = searchString.replaceAll(_offSearchSyntaxChars, ' ').trim();
    final queryParameters = {
      _offSearchQueryTag:
          '$terms $_offSearchCountryFilter $_offSearchCompletenessFilter',
      _offSearchLangsTag: 'fr',
      _offFieldsTag: _getReturnFields(),
      _offPageTag: page.toString(),
      _offPageSizeTag: pageSize.toString(),
      _offSearchSortTag: _offSearchSortByPopularity,
    };

    return Uri.https(_offSearchBaseUrl, _offSearchTag, queryParameters);
  }

  static Uri getOffBarcodeSearchUri(String barcode) {
    final queryParameters = {
      _offFieldsTag: _getReturnFields(),
      _offJsonTag: _offJsonValue
    };

    return Uri.https(
        _offBaseUrl, '$_offProductSearchTag/$barcode', queryParameters);
  }
}
