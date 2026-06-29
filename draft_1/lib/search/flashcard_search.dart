import 'package:draft_1/model.dart';

/// Which kinds of result the search should return.
enum SearchScope {
  /// Both matching decks and matching individual cards.
  all,

  /// Only matching decks.
  decks,

  /// Only matching individual cards.
  cards,
}

/// A single card that matched a search, paired with the deck it lives in so the
/// UI can show context and navigate to the right deck.
class CardHit {
  final Deck deck;
  final Flashcard card;

  const CardHit(this.deck, this.card);
}

/// The outcome of a [searchFlashcards] call: the decks and cards that matched.
class FlashcardSearchResults {
  final List<Deck> decks;
  final List<CardHit> cards;

  const FlashcardSearchResults({this.decks = const [], this.cards = const []});

  bool get isEmpty => decks.isEmpty && cards.isEmpty;
}

/// Splits a free-text query into lower-cased keyword terms. Every term must
/// match for a result to be included (AND semantics), so typing more words
/// narrows the results.
List<String> _terms(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((term) => term.isNotEmpty)
    .toList();

/// True when every term in [terms] appears somewhere in [haystack].
bool _matchesTerms(String haystack, List<String> terms) {
  final lower = haystack.toLowerCase();
  for (final term in terms) {
    if (!lower.contains(term)) return false;
  }
  return true;
}

/// Lower-cased set of tags for case-insensitive comparison.
Set<String> _lower(Iterable<String> tags) =>
    tags.map((t) => t.toLowerCase()).toSet();

/// Searches [decks] (and the cards inside them) by free-text [query], a set of
/// required [tags], and a [scope].
///
/// Matching rules:
///   * Keyword: a deck matches when every term in [query] is found in its name
///     or one of its tags; a card matches when every term is found in its
///     question, answer, its own tags, or its parent deck's name/tags.
///   * Tags: a result must carry *all* of the selected [tags] (AND). A card is
///     considered to carry its parent deck's tags as well, so filtering by a
///     deck-level tag surfaces every card in that deck.
///
/// An empty query and empty [tags] returns everything permitted by [scope],
/// which lets the search screen double as a browse view.
FlashcardSearchResults searchFlashcards(
  List<Deck> decks, {
  String query = '',
  Set<String> tags = const {},
  SearchScope scope = SearchScope.all,
}) {
  final terms = _terms(query);
  final requiredTags = _lower(tags);

  final matchedDecks = <Deck>[];
  final matchedCards = <CardHit>[];

  for (final deck in decks) {
    final deckTagsLower = _lower(deck.tags);

    if (scope != SearchScope.cards) {
      final keywordOk =
          terms.isEmpty || _matchesTerms('${deck.name} ${deck.tags.join(' ')}', terms);
      final tagsOk = requiredTags.every(deckTagsLower.contains);
      if (keywordOk && tagsOk) matchedDecks.add(deck);
    }

    if (scope != SearchScope.decks) {
      for (final card in deck.cards) {
        // A card inherits its deck's tags for filtering purposes.
        final cardTagsLower = {..._lower(card.tags), ...deckTagsLower};
        final tagsOk = requiredTags.every(cardTagsLower.contains);
        if (!tagsOk) continue;

        final haystack = '${card.question} ${card.answer} '
            '${card.tags.join(' ')} ${deck.name} ${deck.tags.join(' ')}';
        if (terms.isEmpty || _matchesTerms(haystack, terms)) {
          matchedCards.add(CardHit(deck, card));
        }
      }
    }
  }

  return FlashcardSearchResults(decks: matchedDecks, cards: matchedCards);
}

/// Every distinct tag used across [decks] and their cards, sorted
/// case-insensitively. Powers the filter chips on the search screen. The first
/// casing seen for a given tag wins.
List<String> allTags(List<Deck> decks) {
  final seen = <String, String>{}; // lower-case -> display casing
  void add(String tag) => seen.putIfAbsent(tag.toLowerCase(), () => tag);
  for (final deck in decks) {
    deck.tags.forEach(add);
    for (final card in deck.cards) {
      card.tags.forEach(add);
    }
  }
  final tags = seen.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return tags;
}
