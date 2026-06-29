import 'package:draft_1/model.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Opens a dialog that lets the user add and remove [initialTags], returning the
/// edited list, or `null` if the dialog was cancelled. Tags are trimmed and
/// de-duplicated (case-insensitively) via [parseTags].
Future<List<String>?> editTags(
  BuildContext context, {
  required List<String> initialTags,
  String title = 'Edit tags',
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _TagEditorDialog(initialTags: initialTags, title: title),
  );
}

class _TagEditorDialog extends StatefulWidget {
  final List<String> initialTags;
  final String title;

  const _TagEditorDialog({required this.initialTags, required this.title});

  @override
  State<_TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<_TagEditorDialog> {
  late final List<String> _tags = parseTags(widget.initialTags);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final added = parseTags([..._tags, _controller.text]);
    setState(() {
      _tags
        ..clear()
        ..addAll(added);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isEmpty)
            Text(
              'No tags yet.',
              style: context.text.bodyMedium?.copyWith(color: colors.neutral),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in _tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
              ],
            ),
          const VGap(AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Add a tag',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTag,
              ),
            ),
            onSubmitted: (_) => _addTag(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(parseTags(_tags)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// A compact, read-only row of tag chips. Renders nothing when [tags] is empty.
class TagChips extends StatelessWidget {
  final List<String> tags;

  const TagChips({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.positive.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '#$tag',
              style: context.text.bodySmall?.copyWith(color: colors.onSurface),
            ),
          ),
      ],
    );
  }
}
