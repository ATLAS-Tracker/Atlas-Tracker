// Word matching shared by the product search (OFF ranking) and the results
// list: "bifidus carrefour vanille" ranks products by how many typed words
// their name and brand contain.

const _accents = [
  ('àâä', 'a'),
  ('éèêë', 'e'),
  ('îï', 'i'),
  ('ôö', 'o'),
  ('ùûü', 'u'),
  ('ç', 'c'),
];

const _stopWords = {
  'de',
  'du',
  'des',
  'la',
  'le',
  'les',
  'au',
  'aux',
  'et',
  'en'
};

final _tokenPattern = RegExp(r'[a-z0-9]+');

/// Lowercase without French accents, so "pate" matches "Pâte".
String foldText(String text) {
  var folded = text.toLowerCase().trim().replaceAll('œ', 'oe');
  for (final (accented, plain) in _accents) {
    folded = folded.replaceAll(RegExp('[$accented]'), plain);
  }
  return folded;
}

Set<String> searchTokens(String text) =>
    _tokenPattern.allMatches(foldText(text)).map((m) => m[0]!).toSet();

/// The meaningful typed words: no stop words, no single letters.
List<String> searchWords(String query) => searchTokens(query)
    .where((w) => w.length > 1 && !_stopWords.contains(w))
    .toList();

/// How many [words] appear in [tokens]; from 3 letters a word also matches
/// as a prefix ("bifidus" in "bifidus*", "yaourt" in "yaourts").
int matchedWordCount(Set<String> tokens, List<String> words) => words
    .where(
        (w) => tokens.any((t) => t == w || (w.length >= 3 && t.startsWith(w))))
    .length;
