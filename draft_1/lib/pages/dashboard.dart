import 'dart:math' as math;

import 'package:draft_1/study_analytics.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Study analytics dashboard: study time, cards reviewed, accuracy, streaks and
/// completed sessions, presented with Material-styled cards and charts that
/// reuse the app's theme colours.
class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final analytics = StudyAnalytics.instance;
    final daily = analytics.dailyStats(days: 7);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          'Study Analytics',
          style: GoogleFonts.nunito(
            color: colors.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatCardGrid(analytics: analytics),
              const SizedBox(height: 24),
              const _SectionTitle('Study time this week'),
              const SizedBox(height: 12),
              _ChartCard(
                child: _StudyTimeBarChart(daily: daily),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Cards reviewed'),
              const SizedBox(height: 12),
              _ChartCard(
                child: _CardsReviewedLineChart(daily: daily),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Accuracy'),
              const SizedBox(height: 12),
              _AccuracyCard(analytics: analytics),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: context.colors.bodyText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive grid of headline stat cards
// ---------------------------------------------------------------------------

class _StatCardGrid extends StatelessWidget {
  final StudyAnalytics analytics;
  const _StatCardGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accuracyPct = (analytics.overallAccuracy * 100).round();

    final cards = <Widget>[
      _StatCard(
        icon: Icons.timer_outlined,
        label: 'Study time',
        value: _formatDuration(analytics.totalStudyTime),
        accent: colors.positive,
      ),
      _StatCard(
        icon: Icons.style_outlined,
        label: 'Cards reviewed',
        value: '${analytics.totalCardsReviewed}',
        accent: colors.positive,
      ),
      _StatCard(
        icon: Icons.track_changes,
        label: 'Accuracy',
        value: '$accuracyPct%',
        accent: colors.positive,
      ),
      _StatCard(
        icon: Icons.local_fire_department,
        label: 'Current streak',
        value: '${analytics.currentStreak} day'
            '${analytics.currentStreak == 1 ? '' : 's'}',
        accent: colors.positive,
      ),
      _StatCard(
        icon: Icons.check_circle_outline,
        label: 'Sessions',
        value: '${analytics.completedSessions}',
        accent: colors.positive,
      ),
    ];

    // Responsive: pick a column count that keeps cards a comfortable width,
    // then lay them out in a Wrap so they reflow on phones and tablets/desktop.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 5
            : width >= 680
                ? 3
                : 2;
        final cardWidth =
            (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: colors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card wrapper used to host the charts
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly study-time bar chart (widget based)
// ---------------------------------------------------------------------------

class _StudyTimeBarChart extends StatelessWidget {
  final List<DailyStat> daily;
  const _StudyTimeBarChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxMinutes = daily.fold<int>(
      0,
      (m, d) => math.max(m, d.studyMinutes),
    );

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in daily)
                Expanded(
                  child: _Bar(
                    label: DateFormat.E().format(d.day).substring(0, 1),
                    valueLabel: d.studyMinutes == 0 ? '' : '${d.studyMinutes}',
                    fraction:
                        maxMinutes == 0 ? 0 : d.studyMinutes / maxMinutes,
                    color: colors.positive,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Minutes per day',
          style: GoogleFonts.nunito(
            color: colors.onSurface.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double fraction;
  final Color color;

  const _Bar({
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            valueLabel,
            style: GoogleFonts.nunito(
              color: colors.onSurface.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                // Keep a sliver of height for non-zero days so they stay visible.
                heightFactor: fraction == 0
                    ? 0.0
                    : (0.06 + 0.94 * fraction).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        color,
                        color.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards-reviewed line chart (CustomPainter)
// ---------------------------------------------------------------------------

class _CardsReviewedLineChart extends StatelessWidget {
  final List<DailyStat> daily;
  const _CardsReviewedLineChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final values = daily.map((d) => d.cardsReviewed.toDouble()).toList();
    final maxValue = values.fold<double>(0, math.max);

    return Column(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              values: values,
              maxValue: maxValue,
              lineColor: colors.positive,
              dotColor: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final d in daily)
              Expanded(
                child: Text(
                  DateFormat.E().format(d.day).substring(0, 1),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final Color dotColor;

  _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad = 8.0;
    const bottomPad = 8.0;
    final chartHeight = size.height - topPad - bottomPad;
    final max = maxValue <= 0 ? 1.0 : maxValue;

    final step = values.length == 1
        ? 0.0
        : size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1 ? size.width / 2 : i * step,
          topPad + chartHeight * (1 - values[i] / max),
        ),
    ];

    // Filled area under the line.
    final fillPath = Path()..moveTo(points.first.dx, size.height - bottomPad);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height - bottomPad)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.35),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // The line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Data point dots.
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = lineColor);
      canvas.drawCircle(p, 2, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values ||
      old.maxValue != maxValue ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}

// ---------------------------------------------------------------------------
// Accuracy card with donut + streak summary
// ---------------------------------------------------------------------------

class _AccuracyCard extends StatelessWidget {
  final StudyAnalytics analytics;
  const _AccuracyCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accuracy = analytics.overallAccuracy;

    return _ChartCard(
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _DonutPainter(
                fraction: accuracy,
                trackColor: colors.onSurface.withValues(alpha: 0.15),
                progressColor: colors.positive,
              ),
              child: Center(
                child: Text(
                  '${(accuracy * 100).round()}%',
                  style: GoogleFonts.nunito(
                    color: colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall accuracy',
                  style: GoogleFonts.nunito(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${analytics.totalCardsReviewed} cards reviewed across '
                  '${analytics.completedSessions} sessions',
                  style: GoogleFonts.nunito(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: colors.positive, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Longest streak: ${analytics.longestStreak} days',
                      style: GoogleFonts.nunito(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double fraction; // 0.0 – 1.0
  final Color trackColor;
  final Color progressColor;

  _DonutPainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Track.
    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Progress arc, starting at the top and sweeping clockwise.
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fraction != fraction ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}
