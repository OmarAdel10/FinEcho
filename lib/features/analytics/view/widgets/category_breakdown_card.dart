import 'dart:math' as math;

import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:flutter/material.dart';

/// Which per-category metric the breakdown card renders.
enum CategoryBreakdownMetric {
  /// Expenses per category.
  spending,

  /// Income per category.
  income,
}

const String _spendingTitle = 'Spending by category';
const String _incomeTitle = 'Income by category';
const String _spendingEmptyMessage = 'No spending in this period.';
const String _incomeEmptyMessage = 'No income in this period.';
const String _uncategorizedLabel = 'Uncategorized';
const String _spendingRingLabel = 'Spending ring by category';
const String _incomeRingLabel = 'Income ring by category';
const double _ringSize = 160;
const double _ringStrokeWidth = 20;
const List<Color> _slicePalette = [
  FinEchoColors.deepGreen,
  FinEchoColors.blue,
  FinEchoColors.softStone,
];

/// A card that breaks the period's spending or income down by category.
class CategoryBreakdownCard extends StatelessWidget {
  /// Creates the category breakdown card.
  const new({
    required this.categoryTotals,
    this.metric = CategoryBreakdownMetric.spending,
    super.key,
  });

  /// The per-category amounts to render, highest first.
  ///
  /// Spending entries carry [CategoryTotal.expenseMinorUnits]; income
  /// entries carry [CategoryTotal.incomeMinorUnits].
  final List<CategoryTotal> categoryTotals;

  /// Which metric the card renders.
  final CategoryBreakdownMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpending = metric == CategoryBreakdownMetric.spending;
    final totalMinorUnits = categoryTotals.fold<int>(
      0,
      (total, categoryTotal) =>
          total +
          (isSpending
              ? categoryTotal.expenseMinorUnits
              : categoryTotal.incomeMinorUnits),
    );
    final ringSemanticsLabel = [
      if (isSpending) _spendingRingLabel else _incomeRingLabel,
      for (final categoryTotal in categoryTotals)
        _ringSliceLabel(categoryTotal),
    ].join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpending ? _spendingTitle : _incomeTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (categoryTotals.isEmpty)
              Text(isSpending ? _spendingEmptyMessage : _incomeEmptyMessage)
            else ...[
              Center(
                child: Semantics(
                  label: ringSemanticsLabel,
                  child: SizedBox(
                    width: _ringSize,
                    height: _ringSize,
                    child: CustomPaint(
                      painter: _CategoryRingPainter(
                        slices: [
                          for (final categoryTotal in categoryTotals)
                            if (totalMinorUnits > 0)
                              (isSpending
                                      ? categoryTotal.expenseMinorUnits
                                      : categoryTotal.incomeMinorUnits) /
                                  totalMinorUnits
                            else
                              0.0,
                        ],
                        trackColor: theme.colorScheme.outlineVariant,
                        strokeWidth: _ringStrokeWidth,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < categoryTotals.length; index++)
                _LegendRow(
                  name: categoryTotals[index].name ?? _uncategorizedLabel,
                  amountMinorUnits: isSpending
                      ? categoryTotals[index].expenseMinorUnits
                      : categoryTotals[index].incomeMinorUnits,
                  color: _slicePalette[index % _slicePalette.length],
                  percent: totalMinorUnits > 0
                      ? ((isSpending
                                    ? categoryTotals[index].expenseMinorUnits
                                    : categoryTotals[index].incomeMinorUnits) *
                                100 /
                                totalMinorUnits)
                            .round()
                      : 0,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const new({
    required this.name,
    required this.amountMinorUnits,
    required this.color,
    required this.percent,
  });

  final String name;
  final int amountMinorUnits;
  final Color color;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(
            _formatMinorUnits(amountMinorUnits),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRingPainter extends CustomPainter {
  const new({
    required this.slices,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// The expense share of each category, in draw order.
  final List<double> slices;

  /// The color of the unfilled ring track.
  final Color trackColor;

  /// The width of the ring stroke.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    var startAngle = -math.pi / 2;
    for (var index = 0; index < slices.length; index++) {
      final sweepAngle = slices[index] * 2 * math.pi;
      if (sweepAngle <= 0) {
        continue;
      }
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = _slicePalette[index % _slicePalette.length],
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryRingPainter oldDelegate) {
    if (trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        slices.length != oldDelegate.slices.length) {
      return true;
    }
    for (var index = 0; index < slices.length; index++) {
      if (slices[index] != oldDelegate.slices[index]) {
        return true;
      }
    }
    return false;
  }
}

String _ringSliceLabel(CategoryTotal categoryTotal) {
  final name = categoryTotal.name ?? _uncategorizedLabel;
  final amount = _formatMinorUnits(
    categoryTotal.expenseMinorUnits + categoryTotal.incomeMinorUnits,
  );
  return '$name $amount';
}

String _formatMinorUnits(int amount) {
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}
