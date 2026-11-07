import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/search_match.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';

Map<String, dynamic> hit(String name, List<String> brands,
        {int? scans, List<String> stores = const []}) =>
    {
      'code': '$name|$brands',
      'product_name': name,
      'brands': brands,
      'stores': stores,
      'unique_scans_n': scans,
    };

List<String> names(List<Map<String, dynamic>> hits) =>
    [for (final h in hits) '${h['product_name']} | ${h['brands'].first}'];

void main() {
  group('searchWords', () {
    test('folds accents and drops stop words and single letters', () {
      expect(searchWords("Blanc de poulet Le Gaulois"),
          ['blanc', 'poulet', 'gaulois']);
      expect(searchWords("Crème fraîche épaisse"),
          ['creme', 'fraiche', 'epaisse']);
      expect(searchWords("chips lay's"), ['chips', 'lay']);
    });
  });

  group('rankHits', () {
    test(
        'all typed words first: the Carrefour bifidus beats popular partial '
        'matches, and a store is not a brand', () {
      final ranked = OFFDataSource.rankHits([
        hit("Crème glacée vanille", ["Carte d'or"], scans: 281),
        hit("Huile d'olive", ["Carrefour"], scans: 180),
        hit("Activia bifidus vanille", ["Activia"],
            scans: 41, stores: ["Carrefour"]),
        hit("Bifidus* saveur vanille", ["Carrefour"], scans: 10),
      ], searchWords("bifidus carrefour vanille"));

      expect(names(ranked), [
        "Bifidus* saveur vanille | Carrefour",
        "Activia bifidus vanille | Activia",
        "Crème glacée vanille | Carte d'or",
        "Huile d'olive | Carrefour",
      ]);
    });

    test('same match: most scanned first, then OFF order', () {
      final ranked = OFFDataSource.rankHits([
        hit("Prince", ["Obscure"]),
        hit("Prince goût chocolat", ["LU"], scans: 102),
        hit("Prince Maxi", ["LU"], scans: 46),
        hit("Prince bis", ["Other"]),
      ], searchWords("prince"));

      expect(names(ranked), [
        "Prince goût chocolat | LU",
        "Prince Maxi | LU",
        "Prince | Obscure",
        "Prince bis | Other",
      ]);
    });
  });

  group('brandWord', () {
    test('a word found in brands rather than names', () {
      final hits = [
        hit("Bifidus fraise", ["Carrefour"]),
        hit("Huile d'olive", ["Carrefour"]),
        hit("Activia bifidus nature", ["Danone"]),
      ];
      expect(OFFDataSource.brandWord(hits, searchWords("bifidus carrefour")),
          'carrefour');
    });

    test('a word no hit contains (brand absent from the first hits)', () {
      final hits = [
        hit("Blanc de poulet", ["Fleury Michon Blanc de poulet"]),
        hit("Blanc de poulet", ["Félix et Lucien"]),
      ];
      expect(
          OFFDataSource.brandWord(
              hits, searchWords("blanc de poulet le gaulois")),
          'gaulois');
    });

    test('not a word more common in names, like "orange"', () {
      final hits = [
        hit("Jus d'orange", ["Tropicana"]),
        hit("Jus d'orange", ["Joker"]),
        hit("Orangina", ["Orangina"]),
      ];
      expect(OFFDataSource.brandWord(hits, searchWords("jus orange")), isNull);
    });

    test('none for a single word or enough full matches', () {
      final hits = [
        for (var i = 0; i < 5; i++) hit("Skyr $i", ["Yoplait"])
      ];
      expect(OFFDataSource.brandWord(hits, searchWords("skyr")), isNull);
      expect(
          OFFDataSource.brandWord(hits, searchWords("skyr yoplait")), isNull);
    });
  });

  test('search URL: relevance order, popularity field, brand filter', () {
    final query = OFFConst.getOffWordSearchUrl('bifidus', brand: 'carrefour')
        .queryParameters;
    expect(query.containsKey('sort_by'), isFalse);
    expect(query['fields'], contains('unique_scans_n'));
    expect(query['q'], startsWith('bifidus brands:carrefour '));
  });
}
