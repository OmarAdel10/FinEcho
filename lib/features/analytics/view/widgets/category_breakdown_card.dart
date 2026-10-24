import 'dart:math' as math;

import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/currency_minor_units.dart';
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
const List<Color> _lightSlicePalette = [
  FinEchoColors.deepGreen,
  Color(0xFF8A6D00),
  FinEchoColors.blue,
  Color(0xFFB4462B),
  FinEchoColors.darkNavy,
  Color(0xFF6A4C93),
];
const List<Color> _darkSlicePalette = [
  Color(0xFF9FE3C9),
  Color(0xFFE0C060),
  Color(0xFF7FB2FF),
  Color(0xFFFF9C7A),
  Color(0xFFC7B2F0),
  FinEchoColors.softStone,
];

/// Returns the slice colors for a breakdown ring rendered with [brightness].
///
/// Neighbouring entries stay distinguishable, and every color keeps at least
/// a 3:1 contrast ratio against the card surface in the matching theme.
@visibleForTesting
List<Color> slicePaletteFor(Brightness brightness) =>
    brightness == Brightness.dark ? _darkSlicePalette : _lightSlicePalette;

/// A card that breaks the period's spending or income down by category.
class CategoryBreakdownCard extends StatelessWidget {
  /// Creates the category breakdown card.
  const new({
    required this.categoryTotals,
    this.metric = CategoryBreakdownMetric.spending,
    this.currency,
    super.key,
  });

  /// The per-category amounts to render, highest first.
  ///
  /// Spending entries carry [CategoryTotal.expenseMinorUnits]; income
  /// entries carry [CategoryTotal.incomeMinorUnits].
  final List<CategoryTotal> categoryTotals;

  /// The ISO currency code the category totals are denominated in.
  final String? currency;

  /// Which metric the card renders.
  final CategoryBreakdownMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = slicePaletteFor(theme.brightness);
    final isSpending = metric == CategoryBreakdownMetric.spending;
    final totalMinorUnits = categoryTotals.fold<int>(
      0,
      (total, categoryTotal) =>
          total +
          (isSpending
              ? categoryTotal.expenseMinorUnits
              : categoryTotal.incomeMinorUnits),
    );
    final amounts = <int>[
      for (final categoryTotal in categoryTotals)
        if (isSpending)
          categoryTotal.expenseMinorUnits
        else
          categoryTotal.incomeMinorUnits,
    ];
    final legendPercents = _legendPercents(amounts, totalMinorUnits);
    final ringSemanticsLabel = [
      if (isSpending) _spendingRingLabel else _incomeRingLabel,
      for (final categoryTotal in categoryTotals)
        _ringSliceLabel(categoryTotal, currency),
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
                          for (final amount in amounts)
                            if (totalMinorUnits > 0)
                              amount / totalMinorUnits
                            else
                              0.0,
                        ],
                        colors: palette,
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
                  amountMinorUnits: amounts[index],
                  color: palette[index % palette.length],
                  percent: legendPercents[index],
                  currency: currency,
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
    required this.currency,
  });

  final String name;
  final int amountMinorUnits;
  final Color color;
  final int percent;

  /// The ISO currency code the amounts are denominated in.
  final String? currency;

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
            formatMinorUnits(amountMinorUnits, currency),
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
    required this.colors,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// The expense share of each category, in draw order.
  final List<double> slices;

  /// The slice colors, applied in draw order and cycling when exhausted.
  final List<Color> colors;

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
          ..color = colors[index % colors.length],
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryRingPainter oldDelegate) {
    if (trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        slices.length != oldDelegate.slices.length ||
        colors.length != oldDelegate.colors.length) {
      return true;
    }
    for (var index = 0; index < slices.length; index++) {
      if (slices[index] != oldDelegate.slices[index]) {
        return true;
      }
    }
    for (var index = 0; index < colors.length; index++) {
      if (colors[index] != oldDelegate.colors[index]) {
        return true;
      }
    }
    return false;
  }
}

String _ringSliceLabel(CategoryTotal categoryTotal, String? currency) {
  final name = categoryTotal.name ?? _uncategorizedLabel;
  final amount = formatMinorUnits(
    categoryTotal.expenseMinorUnits + categoryTotal.incomeMinorUnits,
    currency,
  );
  return '$name $amount';
}

/// Splits 100 percent across [amounts] with the largest-remainder method so
/// the legend always sums to exactly 100 when [total] is positive.
List<int> _legendPercents(List<int> amounts, int total) {
  if (total <= 0) {
    return List<int>.filled(amounts.length, 0);
  }
  final exact = [for (final amount in amounts) amount * 100 / total];
  final result = [for (final value in exact) value.floor()];
  final order = List<int>.generate(amounts.length, (index) => index)
    ..sort((a, b) {
      final remainderComparison = (exact[b] - result[b]).compareTo(
        exact[a] - result[a],
      );
      return remainderComparison != 0 ? remainderComparison : a.compareTo(b);
    });
  var remainder = 100 - result.fold<int>(0, (sum, value) => sum + value);
  for (var index = 0; index < order.length && remainder > 0; index++) {
    result[order[index]]++;
    remainder--;
  }
  return result;
}
