import 'package:flutter/material.dart';
import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class UserTests extends StatelessWidget {
  const UserTests({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Tests')),
      body: globals.tests.isEmpty
          ? const AppEmptyState(
              icon: Icons.event_note_outlined,
              title: 'No tests yet',
              message: 'Add a test from the "+" tab and it will show up here, '
                  'ready for a study plan.',
            )
          : ListView.builder(
              itemCount: globals.tests.length,
              itemBuilder: (context, index) {
                final test = globals.tests[index];
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: EntranceFade.staggered(
                    index: index,
                    child: AppCard(
                      onTap: () => _showTestDetails(context, test),
                      radius: AppRadius.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.subject,
                            style: context.text.titleMedium
                                ?.copyWith(color: colors.onSurface),
                          ),
                          const VGap(AppSpacing.sm),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(test.testDate)}',
                            style: context.text.bodyLarge
                                ?.copyWith(color: colors.onSurface),
                          ),
                          Text(
                            'Type: ${test.testType.toString().split('.').last}',
                            style: context.text.bodyLarge
                                ?.copyWith(color: colors.onSurface),
                          ),
                          Text(
                            'Difficulty: '
                            '${test.testDifficulty.toString().split('.').last}',
                            style: context.text.bodyLarge
                                ?.copyWith(color: colors.onSurface),
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

  void _showTestDetails(BuildContext context, Test test) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(test.subject),
          content: Text(
            'Date: ${DateFormat('yyyy-MM-dd').format(test.testDate)}\n'
            'Type: ${test.testType.toString().split('.').last}\n'
            'Difficulty: ${test.testDifficulty.toString().split('.').last}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }
}
