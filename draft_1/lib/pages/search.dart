import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/pages/flashcards.dart';
import 'package:draft_1/search/flashcard_search.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:draft_1/widgets/tag_editor.dart';
import 'package:flutter/material.dart';

/// Full-text search and tag/scope filtering across every [Deck] and the cards
/// inside them. Results recompute on every keystroke and chip toggle, so the
/// list updates instantly while the user types.
class FlashcardSearchScreen extends StatefulWidget {
  const FlashcardSearchScreen({super.key});

  @override
  State<FlashcardSearchScreen> createState() => _FlashcardSearchScreenState();
}

class _FlashcardSearchScreenState extends State<FlashcardSearchScreen> {
  final _queryController = TextEditingController();
  final _selectedTags = <String>{};
  SearchScope _scope = SearchScope.all;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _openDeck(Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
    );
    // Tags/cards may have changed in the detail screen; refresh results.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tags = allTags(globals.decks);
    // Drop selected tags that no longer exist (e.g. removed in a detail screen).
    _selectedTags.removeWhere((t) => !tags.contains(t));

    final results = searchFlashcards(
      globals.decks,
      query: _queryController.text,
      tags: _selectedTags,
      scope: _scope,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search decks, cards and tags…',
                prefixIcon: Icon(Icons.search, color: colors.onSurface),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.clear, color: colors.onSurface),
                        onPressed: () =>
                            setState(() => _queryController.clear()),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _ScopeSelector(
            scope: _scope,
            onChanged: (scope) => setState(() => _scope = scope),
          ),
          if (tags.isNotEmpty)
            _TagFilterBar(
              tags: tags,
              selected: _selectedTags,
              onToggled: (tag, selected) => setState(() {
                if (selected) {
                  _selectedTags.add(tag);
                } else {
                  _selectedTags.remove(tag);
                }
              }),
            ),
          const Divider(height: 1),
          Expanded(child: _buildResults(results)),
        ],
      ),
    );
  }

  Widget _buildResults(FlashcardSearchResults results) {
    final colors = context.colors;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No matches.\nTry different keywords or clear a filter.',
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: colors.bodyText),
          ),
        ),
      );
    }

    final showDecks = results.decks.isNotEmpty;
    final showCards = results.cards.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (showDecks) ...[
          _SectionHeader('Decks (${results.decks.length})'),
          for (final deck in results.decks)
            _DeckResultTile(deck: deck, onTap: () => _openDeck(deck)),
        ],
        if (showCards) ...[
          _SectionHeader('Cards (${results.cards.length})'),
          for (final hit in results.cards)
            _CardResultTile(hit: hit, onTap: () => _openDeck(hit.deck)),
        ],
      ],
    );
  }
}

/// All / Decks / Cards segmented control above the results.
class _ScopeSelector extends StatelessWidget {
  final SearchScope scope;
  final ValueChanged<SearchScope> onChanged;

  const _ScopeSelector({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SegmentedButton<SearchScope>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: SearchScope.all, label: Text('All')),
          ButtonSegment(value: SearchScope.decks, label: Text('Decks')),
          ButtonSegment(value: SearchScope.cards, label: Text('Cards')),
        ],
        selected: {scope},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Horizontally scrolling row of tag [FilterChip]s.
class _TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final void Function(String tag, bool selected) onToggled;

  const _TagFilterBar({
    required this.tags,
    required this.selected,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const HGap(AppSpacing.sm),
        itemBuilder: (context, index) {
          final tag = tags[index];
          return Center(
            child: FilterChip(
              label: Text('#$tag'),
              selected: selected.contains(tag),
              selectedColor: colors.positive.withValues(alpha: 0.3),
              onSelected: (value) => onToggled(tag, value),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: context.text.titleMedium?.copyWith(color: context.colors.accentText),
      ),
    );
  }
}

class _DeckResultTile extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const _DeckResultTile({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        radius: AppRadius.sm,
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.style, color: colors.onSurface),
            const HGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: context.text.titleMedium
                        ?.copyWith(color: colors.onSurface),
                  ),
                  if (deck.tags.isNotEmpty) ...[
                    const VGap(AppSpacing.xs),
                    TagChips(tags: deck.tags),
                  ],
                ],
              ),
            ),
            const HGap(AppSpacing.sm),
            Text(
              '${deck.cards.length} '
              '${deck.cards.length == 1 ? 'card' : 'cards'}',
              style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardResultTile extends StatelessWidget {
  final CardHit hit;
  final VoidCallback onTap;

  const _CardResultTile({required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = hit.card;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        radius: AppRadius.sm,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.question,
              style:
                  context.text.titleMedium?.copyWith(color: colors.onSurface),
            ),
            const VGap(AppSpacing.xs),
            Text(
              card.answer,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium
                  ?.copyWith(color: colors.onSurface.withValues(alpha: 0.85)),
            ),
            const VGap(AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.style, size: 14, color: colors.neutral),
                const HGap(AppSpacing.xs),
                Expanded(
                  child: Text(
                    hit.deck.name,
                    style: context.text.bodySmall
                        ?.copyWith(color: colors.neutral),
                  ),
                ),
              ],
            ),
            if (card.tags.isNotEmpty) ...[
              const VGap(AppSpacing.sm),
              TagChips(tags: card.tags),
            ],
          ],
        ),
      ),
    );
  }
}
