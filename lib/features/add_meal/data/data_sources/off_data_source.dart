import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/core/utils/search_match.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class OFFDataSource {
  static const _timeoutDuration = Duration(seconds: 20); // TODO lower timeout
  final log = Logger('OFFDataSource');

  /// OFF matches products containing ANY typed word, so the hits are ranked
  /// here by matched words. On the first page, a typed brand ("carrefour")
  /// gets a second, brand-filtered search: its products may not be among the
  /// first hits of a common word.
  Future<List<OFFProductDTO>> fetchSearchWordResults(String searchString,
      {int page = 1, int pageSize = 20}) async {
    try {
      final words = searchWords(searchString);
      final hits = await _fetchSearchHits(OFFConst.getOffWordSearchUrl(
          searchString,
          page: page,
          pageSize: pageSize));
      final brand = page == 1 ? brandWord(hits, words) : null;
      if (brand != null) {
        // A failing brand search only loses its extra results.
        final brandHits = await _fetchSearchHits(OFFConst.getOffWordSearchUrl(
                words.where((w) => w != brand).join(' '),
                pageSize: pageSize,
                brand: brand))
            .catchError((_) => <Map<String, dynamic>>[]);
        final codes = {for (final hit in hits) hit['code']};
        hits.addAll(brandHits.where((hit) => !codes.contains(hit['code'])));
      }
      return rankHits(hits, words).map((hit) {
        // search-a-licious returns brands as a list, the DTO as a string.
        final brands = hit['brands'];
        if (brands is List) hit['brands'] = brands.join(', ');
        // It doesn't index product_quantity either, rebuild it from "400 g".
        hit['product_quantity'] ??= _packageQuantity(hit['quantity']);
        return OFFProductDTO.fromJson(hit);
      }).toList();
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);
      return Future.error(exception);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSearchHits(Uri searchUrl) async {
    final userAgentString = await AppConst.getUserAgentString();
    final httpClient = ONTHttpClient(userAgentString, http.Client());

    final response = await httpClient.get(searchUrl).timeout(_timeoutDuration);
    log.fine('Fetching OFF results from: $searchUrl');
    if (response.statusCode != OFFConst.offHttpSuccessCode) {
      log.warning('Failed OFF call: ${response.statusCode}');
      return Future.error(response.statusCode);
    }
    // No charset in the response header, http would fall back to latin1.
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body['hits'] as List)
        .cast<Map<String, dynamic>>()
        .where((hit) =>
            hit['nutriments'] != null &&
            [hit['product_name'], hit['product_name_fr']]
                .any((name) => name is String && name.trim().isNotEmpty))
        .toList();
  }

  static Set<String> _hitTokens(Map<String, dynamic> hit,
          {bool name = true, bool brands = true}) =>
      searchTokens([
        if (name) ...[hit['product_name'], hit['product_name_fr']],
        if (brands)
          ...(hit['brands'] is List ? hit['brands'] as List : [hit['brands']]),
      ].whereType<String>().join(' '));

  /// Most matched words first (name and brand, not the stores selling it),
  /// then most scanned, then OFF's relevance order.
  @visibleForTesting
  static List<Map<String, dynamic>> rankHits(
      List<Map<String, dynamic>> hits, List<String> words) {
    final ranked = [
      for (final (i, hit) in hits.indexed)
        (
          matchedWordCount(_hitTokens(hit), words),
          (hit['unique_scans_n'] as num?) ?? 0,
          i,
          hit
        )
    ];
    ranked.sort((a, b) => a.$1 != b.$1
        ? b.$1 - a.$1
        : a.$2 != b.$2
            ? b.$2.compareTo(a.$2)
            : a.$3 - b.$3);
    return [for (final r in ranked) r.$4];
  }

  /// The typed word worth a brand-filtered search, if the hits lack products
  /// matching every word: one no hit contains (the brand's products are
  /// missing), else one found more often in brands than in product names
  /// ("carrefour" yes, "orange" or "blanc" no).
  @visibleForTesting
  static String? brandWord(
      List<Map<String, dynamic>> hits, List<String> words) {
    if (words.length < 2) return null;
    final fullMatches = hits
        .where(
            (hit) => matchedWordCount(_hitTokens(hit), words) == words.length)
        .length;
    if (fullMatches >= 5) return null;

    for (final word in words) {
      if (!hits.any((hit) => matchedWordCount(_hitTokens(hit), [word]) > 0)) {
        return word;
      }
    }
    int margin(String word) =>
        hits
            .where((hit) => _hitTokens(hit, name: false).contains(word))
            .length -
        hits
            .where((hit) => _hitTokens(hit, brands: false).contains(word))
            .length;
    final best = words.reduce((a, b) => margin(b) > margin(a) ? b : a);
    return margin(best) > 0 ? best : null;
  }

  static final _quantityPattern =
      RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|cl|ml|l)\b', caseSensitive: false);
  static const _toBaseUnit = {'kg': 1000, 'g': 1, 'l': 1000, 'cl': 10, 'ml': 1};

  /// "400 g" -> 400, "1,5 L" -> 1500 (g or ml). Null for "6 x 125 g" etc.
  static num? _packageQuantity(Object? quantity) {
    final match =
        _quantityPattern.firstMatch(quantity is String ? quantity : '');
    if (match == null) return null;
    final value = double.parse(match[1]!.replaceAll(',', '.'));
    return value * _toBaseUnit[match[2]!.toLowerCase()]!;
  }

  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    try {
      final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response =
          await httpClient.get(searchUrl).timeout(_timeoutDuration);
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
