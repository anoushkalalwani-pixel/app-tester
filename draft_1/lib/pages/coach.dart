import 'package:draft_1/OpenAIAPI.dart';
import 'package:draft_1/study_coach.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Personalized AI study coach.
///
/// Analyses the user's study history and upcoming tests (via [StudyCoach]) and
/// recommends which subjects to review next. A deterministic, offline ranking
/// is shown instantly so the screen is never empty, then enriched with the AI
/// provider's natural-language recommendations when they arrive. If the AI
/// provider is unavailable the offline ranking remains, with a quiet notice.
class UserCoach extends StatefulWidget {
  const UserCoach({super.key});

  @override
  State<UserCoach> createState() => _UserCoachState();
}

class _UserCoachState extends State<UserCoach> {
  final StudyCoach _coach = StudyCoach.instance;

  late List<SubjectInsight> _insights;
  late Map<String, SubjectInsight> _insightBySubject;
  late List<Recommendation> _recommendations;

  bool _loadingAi = false;
  bool _aiPowered = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _insights = _coach.subjectInsights();
    _insightBySubject = {
      for (final insight in _insights) insight.subject.toLowerCase(): insight,
    };
    _recommendations = _coach.localRecommendations();
    if (_insights.isNotEmpty) {
      _refreshWithAi();
    }
  }

  Future<void> _refreshWithAi() async {
    setState(() {
      _loadingAi = true;
      _notice = null;
    });
    try {
      final ai = await OpenAIAPI().generateStudyRecommendations(_insights);
      if (!mounted) return;
      setState(() {
        if (ai.isEmpty) {
          _aiPowered = false;
          _recommendations = _coach.localRecommendations();
          _notice = 'The AI coach had no extra suggestions — '
              'showing the ranking from your study history.';
        } else {
          _aiPowered = true;
          _recommendations = ai;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiPowered = false;
        _recommendations = _coach.localRecommendations();
        _notice = 'Showing an offline ranking from your study history '
            '(the AI coach is unavailable right now).';
      });
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Coach'),
        actions: [
          if (_loadingAi)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_insights.isNotEmpty)
            IconButton(
              tooltip: 'Refresh recommendations',
              icon: const Icon(Icons.refresh),
              onPressed: _refreshWithAi,
            ),
        ],
      ),
      body: _insights.isEmpty ? const _EmptyState() : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _CoachHeader(aiPowered: _aiPowered, notice: _notice),
        const VGap(AppSpacing.lg),
        for (final rec in _recommendations) ...[
          _RecommendationCard(
            recommendation: rec,
            insight: _insightBySubject[rec.subject.toLowerCase()],
          ),
          const VGap(AppSpacing.md),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _CoachHeader extends StatelessWidget {
  final bool aiPowered;
  final String? notice;

  const _CoachHeader({required this.aiPowered, this.notice});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colors.positive),
              const HGap(AppSpacing.sm),
              Expanded(
                child: Text(
                  'What to review next',
                  style: context.text.titleMedium
                      ?.copyWith(color: colors.onSurface),
                ),
              ),
              if (aiPowered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.positive.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: colors.positive),
                      const HGap(AppSpacing.xs),
                      Text(
                        'AI',
                        style: context.text.labelSmall
                            ?.copyWith(color: colors.positive),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const VGap(AppSpacing.sm),
          Text(
            notice ??
                'Ranked from how often you study each subject, how well you '
                    'perform, and when your tests are.',
            style: context.text.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendation card
// ---------------------------------------------------------------------------

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final SubjectInsight? insight;

  const _RecommendationCard({required this.recommendation, this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _priorityColor(context, recommendation.priority);

    return AppCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation.subject,
                  style: context.text.titleMedium
                      ?.copyWith(color: colors.onSurface),
                ),
              ),
              _PriorityChip(priority: recommendation.priority, color: accent),
            ],
          ),
          const VGap(AppSpacing.sm),
          Text(
            recommendation.reason,
            style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
          ),
          if (insight != null) ...[
            const VGap(AppSpacing.md),
            _StatChips(insight: insight!),
          ],
          const VGap(AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: colors.positive),
              const HGap(AppSpacing.sm),
              Expanded(
                child: Text(
                  recommendation.suggestedAction,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _priorityColor(BuildContext context, ReviewPriority priority) {
    final colors = context.colors;
    return switch (priority) {
      ReviewPriority.high => colors.danger,
      ReviewPriority.medium => colors.warning,
      ReviewPriority.low => colors.positive,
    };
  }
}

class _PriorityChip extends StatelessWidget {
  final ReviewPriority priority;
  final Color color;

  const _PriorityChip({required this.priority, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      ReviewPriority.high => 'High',
      ReviewPriority.medium => 'Medium',
      ReviewPriority.low => 'Low',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Small supporting-stat chips that show the evidence behind a recommendation.
class _StatChips extends StatelessWidget {
  final SubjectInsight insight;

  const _StatChips({required this.insight});

  @override
  Widget build(BuildContext context) {
    final chips = <_Stat>[];

    if (insight.accuracy != null) {
      chips.add(_Stat(
        Icons.track_changes,
        '${(insight.accuracy! * 100).round()}% accuracy',
      ));
    }
    if (insight.daysSinceLastStudied != null) {
      chips.add(_Stat(
        Icons.history,
        insight.daysSinceLastStudied == 0
            ? 'Reviewed today'
            : '${insight.daysSinceLastStudied}d since review',
      ));
    } else {
      chips.add(const _Stat(Icons.history, 'Never reviewed'));
    }
    if (insight.daysUntilTest != null) {
      chips.add(_Stat(
        Icons.event,
        switch (insight.daysUntilTest!) {
          0 => 'Test today',
          1 => 'Test tomorrow',
          final d => 'Test in ${d}d',
        },
      ));
    }

    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final stat in chips)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stat.icon,
                    size: 14, color: colors.onSurface.withValues(alpha: 0.7)),
                const HGap(AppSpacing.xs),
                Text(
                  stat.label,
                  style: context.text.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  const _Stat(this.icon, this.label);
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology,
                size: 56, color: colors.bodyText.withValues(alpha: 0.5)),
            const VGap(AppSpacing.lg),
            Text(
              'Your coach needs some data first',
              textAlign: TextAlign.center,
              style:
                  context.text.titleMedium?.copyWith(color: colors.bodyText),
            ),
            const VGap(AppSpacing.sm),
            Text(
              'Log a study session or add a test, and the AI coach will tell '
              'you which subjects to review next.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: colors.bodyText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
