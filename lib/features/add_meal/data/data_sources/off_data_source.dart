import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class OFFDataSource {
  static const _timeoutDuration = Duration(seconds: 20); // TODO lower timeout
  final log = Logger('OFFDataSource');

  Future<List<OFFProductDTO>> fetchSearchWordResults(String searchString,
      {int page = 1, int pageSize = 20}) async {
    try {
      final searchUrlString =
          OFFConst.getOffWordSearchUrl(searchString, page: page, pageSize: pageSize);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response = await httpClient
          .get(searchUrlString)
          .timeout(_timeoutDuration);
      log.fine('Fetching OFF results from: $searchUrlString');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        // No charset in the response header, http would fall back to latin1.
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final hits = (body['hits'] as List)
            .cast<Map<String, dynamic>>()
            .where((hit) =>
                hit['nutriments'] != null &&
                [hit['product_name'], hit['product_name_fr']]
                    .any((name) => name is String && name.trim().isNotEmpty))
            .map((hit) {
          // search-a-licious returns brands as a list, the DTO as a string.
          final brands = hit['brands'];
          if (brands is List) hit['brands'] = brands.join(', ');
          // It doesn't index product_quantity either, rebuild it from "400 g".
          hit['product_quantity'] ??= _packageQuantity(hit['quantity']);
          return OFFProductDTO.fromJson(hit);
        }).toList();
        log.fine('Successful response from OFF');
        return hits;
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);
      return Future.error(exception);
    }
  }

  static final _quantityPattern =
      RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|cl|ml|l)\b', caseSensitive: false);
  static const _toBaseUnit = {'kg': 1000, 'g': 1, 'l': 1000, 'cl': 10, 'ml': 1};

  /// "400 g" -> 400, "1,5 L" -> 1500 (g or ml). Null for "6 x 125 g" etc.
  static num? _packageQuantity(Object? quantity) {
    final match = _quantityPattern.firstMatch(quantity is String ? quantity : '');
    if (match == null) return null;
    final value = double.parse(match[1]!.replaceAll(',', '.'));
    return value * _toBaseUnit[match[2]!.toLowerCase()]!;
  }

  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    try {
      final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response = await httpClient
          .get(searchUrl)
          .timeout(_timeoutDuration);
      log.fine('Fetching OFF result from: $searchUrl');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final productResponse = OFFProductResponseDTO.fromJson(
          jsonDecode(response.body),
        );
        log.fine('Successful response from OFF');
        return productResponse;
      } else if (response.statusCode == OFFConst.offProductNotFoundCode) {
        log.warning("404 OFF Product not found");
        return Future.error(ProductNotFoundException);
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF barcode search $exception');
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);
      return Future.error(exception);
    }
  }
}
