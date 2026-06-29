import 'package:flutter/material.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/OpenAIAPI.dart';
import 'package:draft_1/theme/app_theme.dart';

/// Decks home: lists every saved [Deck] and is the entry point for generating
/// new flashcards from notes with the AI provider.
class UserFlashcards extends StatefulWidget {
  const UserFlashcards({super.key});

  @override
  State<UserFlashcards> createState() => _UserFlashcardsState();
}

class _UserFlashcardsState extends State<UserFlashcards> {
  Future<void> _openGenerator() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GenerateFlashcardsScreen()),
    );
    // The generator may have saved cards into a deck; refresh the list.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGenerator,
        backgroundColor: colors.positive,
        foregroundColor: colors.onSurface,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate'),
      ),
      body: globals.decks.isEmpty
          ? Center(
              child: Text(
                'No decks yet.\nTap Generate to create flashcards from your notes.',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: colors.bodyText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: globals.decks.length,
              itemBuilder: (context, index) {
                final deck = globals.decks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: AppCard(
                    radius: AppRadius.sm,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeckDetailScreen(deck: deck),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Row(
                      children: [
                        Icon(Icons.style, color: colors.onSurface),
                        const HGap(AppSpacing.md),
                        Expanded(
                          child: Text(
                            deck.name,
                            style: context.text.titleMedium
                                ?.copyWith(color: colors.onSurface),
                          ),
                        ),
                        Text(
                          '${deck.cards.length} '
                          '${deck.cards.length == 1 ? 'card' : 'cards'}',
                          style: context.text.bodyLarge
                              ?.copyWith(color: colors.onSurface),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Lets the user paste notes and asks the AI provider to draft flashcards.
class GenerateFlashcardsScreen extends StatefulWidget {
  const GenerateFlashcardsScreen({super.key});

  @override
  State<GenerateFlashcardsScreen> createState() =>
      _GenerateFlashcardsScreenState();
}

class _GenerateFlashcardsScreenState extends State<GenerateFlashcardsScreen> {
  final _notesController = TextEditingController();
  double _count = 10;
  bool _isGenerating = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      _showSnack('Please paste some notes first.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final cards = await OpenAIAPI()
          .generateFlashcards(notes, count: _count.round());
      if (!mounted) return;
      if (cards.isEmpty) {
        _showSnack('The AI did not return any flashcards. Try richer notes.');
        return;
      }
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReviewFlashcardsScreen(cards: cards),
        ),
      );
      // If cards were saved into a deck, bubble back out to the decks list.
      if (saved == true && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showSnack('Could not generate flashcards: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldStyle =
        context.text.bodyLarge?.copyWith(color: colors.onSurface);
    return Scaffold(
      appBar: AppBar(title: const Text('Generate flashcards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Paste your notes',
            style:
                context.text.titleMedium?.copyWith(color: colors.accentText),
          ),
          const VGap(AppSpacing.md),
          AppCard(
            child: TextField(
              controller: _notesController,
              maxLines: 10,
              minLines: 6,
              style: fieldStyle,
              decoration: AppInputs.onCard(
                context,
                hint: 'e.g. The mitochondria is the powerhouse of the cell...',
              ),
            ),
          ),
          const VGap(AppSpacing.xl),
          Text(
            'Number of cards: ${_count.round()}',
            style: context.text.titleMedium?.copyWith(color: colors.bodyText),
          ),
          Slider(
            value: _count,
            min: 3,
            max: 20,
            divisions: 17,
            label: _count.round().toString(),
            activeColor: colors.positive,
            onChanged: _isGenerating
                ? null
                : (value) => setState(() => _count = value),
          ),
          const VGap(AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generate,
            style: AppButtons.positive(context),
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? 'Generating…' : 'Generate flashcards'),
          ),
        ],
      ),
    );
  }
}

/// Shows the AI-drafted cards so the user can edit, drop, or keep them before
/// committing into a deck. Pops `true` once cards have been saved.
class ReviewFlashcardsScreen extends StatefulWidget {
  final List<Flashcard> cards;

  const ReviewFlashcardsScreen({super.key, required this.cards});

  @override
  State<ReviewFlashcardsScreen> createState() => _ReviewFlashcardsScreenState();
}

class _ReviewFlashcardsScreenState extends State<ReviewFlashcardsScreen> {
  // Editable working copy plus a per-card "keep this one" flag.
  late final List<_EditableCard> _cards = widget.cards
      .map((c) => _EditableCard(
            question: TextEditingController(text: c.question),
            answer: TextEditingController(text: c.answer),
          ))
      .toList();

  @override
  void dispose() {
    for (final card in _cards) {
      card.question.dispose();
      card.answer.dispose();
    }
    super.dispose();
  }

  int get _selectedCount => _cards.where((c) => c.keep).length;

  Future<void> _save() async {
    final selected = _cards.where((c) => c.keep).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one card to save.')),
      );
      return;
    }

    final deck = await _pickDeck();
    if (deck == null || !mounted) return;

    for (final card in selected) {
      final question = card.question.text.trim();
      final answer = card.answer.text.trim();
      if (question.isEmpty || answer.isEmpty) continue;
      deck.cards.add(Flashcard(question: question, answer: answer));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${selected.length} '
            '${selected.length == 1 ? 'card' : 'cards'} to "${deck.name}".'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  /// Dialog to choose an existing deck or create a new one.
  Future<Deck?> _pickDeck() {
    return showDialog<Deck>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Save to deck'),
          children: [
            for (final deck in globals.decks)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(deck),
                child: Text('${deck.name}  (${deck.cards.length})'),
              ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () async {
                final created = await _promptNewDeck(context);
                if (created != null && context.mounted) {
                  Navigator.of(context).pop(created);
                }
              },
              child: const Row(
                children: [
                  Icon(Icons.add),
                  SizedBox(width: AppSpacing.sm),
                  Text('New deck…'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Deck?> _promptNewDeck(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New deck'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Deck name'),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty) return null;
    final deck = Deck(name: name);
    globals.decks.add(deck);
    return deck;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldStyle =
        context.text.bodyLarge?.copyWith(color: colors.onSurface);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review flashcards'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: _save,
            style: AppButtons.positive(context),
            icon: const Icon(Icons.save),
            label: Text('Save $_selectedCount selected'),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Opacity(
              opacity: card.keep ? 1.0 : 0.5,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Card ${index + 1}',
                          style: context.text.titleMedium
                              ?.copyWith(color: colors.accentText),
                        ),
                        const Spacer(),
                        // Keep / drop this card from the save set.
                        Checkbox(
                          value: card.keep,
                          onChanged: (value) => setState(
                              () => card.keep = value ?? true),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: Icon(Icons.delete_outline,
                              color: colors.onSurface),
                          onPressed: () =>
                              setState(() => _cards.removeAt(index)),
                        ),
                      ],
                    ),
                    TextField(
                      controller: card.question,
                      style: fieldStyle,
                      decoration:
                          AppInputs.onCard(context, hint: 'Question'),
                    ),
                    const Divider(),
                    TextField(
                      controller: card.answer,
                      style: fieldStyle,
                      maxLines: null,
                      decoration: AppInputs.onCard(context, hint: 'Answer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Mutable editing state for a single card on the review screen.
class _EditableCard {
  final TextEditingController question;
  final TextEditingController answer;
  bool keep = true;

  _EditableCard({required this.question, required this.answer});
}

/// Read-only view of the cards inside a single deck.
class DeckDetailScreen extends StatelessWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      body: deck.cards.isEmpty
          ? Center(
              child: Text(
                'This deck is empty.',
                style: context.text.bodyLarge?.copyWith(color: colors.bodyText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: deck.cards.length,
              itemBuilder: (context, index) {
                final card = deck.cards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.question,
                          style: context.text.titleMedium
                              ?.copyWith(color: colors.onSurface),
                        ),
                        const VGap(AppSpacing.sm),
                        Text(
                          card.answer,
                          style: context.text.bodyLarge
                              ?.copyWith(color: colors.onSurface),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
