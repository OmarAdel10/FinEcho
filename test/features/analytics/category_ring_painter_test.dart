import 'dart:math' as math;

import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view/widgets/category_breakdown_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _ArcRecord = ({
  Rect rect,
  double startAngle,
  double sweepAngle,
  bool useCenter,
  Paint paint,
});

typedef _CircleRecord = ({Offset center, double radius, Paint paint});

class _RecordingCanvas implements Canvas {
  final circles = <_CircleRecord>[];
  final arcs = <_ArcRecord>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add((center: c, radius: radius, paint: paint));
  }

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    arcs.add((
      rect: rect,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      useCenter: useCenter,
      paint: paint,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'unexpected canvas call: ${invocation.memberName}',
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

CustomPainter _ringPainterOf(WidgetTester tester) {
  // Material wraps the card in its own CustomPaint (null painter), so
  // the ring is the only descendant CustomPaint that paints directly.
  final paintWidget = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CategoryBreakdownCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter != null,
      ),
    ),
  );
  return paintWidget.painter!;
}

List<CategoryTotal> _totals(int count, {int expenseMinorUnits = 1000}) {
  return [
    for (var index = 0; index < count; index++)
      CategoryTotal(
        categoryId: 'category-$index',
        name: 'Category $index',
        expenseMinorUnits: expenseMinorUnits,
      ),
  ];
}

void main() {
  testWidgets('draws the track and one arc per non-empty slice', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(2))),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    expect(canvas.circles, hasLength(1));
    expect(canvas.circles.single.center, const Offset(80, 80));
    expect(canvas.circles.single.radius, closeTo(70, 1e-9));
    expect(canvas.circles.single.paint.style, PaintingStyle.stroke);
    expect(canvas.circles.single.paint.strokeWidth, 20);
    final theme = Theme.of(tester.element(find.byType(CategoryBreakdownCard)));
    expect(
      canvas.circles.single.paint.color.toARGB32(),
      theme.colorScheme.outlineVariant.toARGB32(),
    );

    final palette = slicePaletteFor(Brightness.light);
    expect(canvas.arcs, hasLength(2));
    final expectedRect = Rect.fromCircle(
      center: const Offset(80, 80),
      radius: 70,
    );
    for (var index = 0; index < canvas.arcs.length; index++) {
      final arc = canvas.arcs[index];
      expect(arc.rect, expectedRect);
      expect(arc.useCenter, isFalse);
      expect(arc.startAngle, closeTo(-math.pi / 2 + index * math.pi, 1e-9));
      expect(arc.sweepAngle, closeTo(math.pi, 1e-9));
      expect(arc.paint.style, PaintingStyle.stroke);
      expect(arc.paint.strokeWidth, 20);
      expect(arc.paint.color.toARGB32(), palette[index].toARGB32());
    }
  });

  testWidgets('cycles palette colors after six slices', (tester) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(8))),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    final palette = slicePaletteFor(Brightness.light);
    expect(canvas.arcs, hasLength(8));
    for (var index = 0; index < canvas.arcs.length; index++) {
      expect(
        canvas.arcs[index].paint.color.toARGB32(),
        palette[index % palette.length].toARGB32(),
      );
      expect(canvas.arcs[index].sweepAngle, closeTo(2 * math.pi / 8, 1e-9));
    }
  });

  testWidgets('skips zero-amount slices but keeps the track', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryBreakdownCard(categoryTotals: _totals(1, expenseMinorUnits: 0)),
      ),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    expect(canvas.arcs, isEmpty);
    expect(canvas.circles, hasLength(1));
  });

  testWidgets('keeps the palette slot of skipped zero slices', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CategoryBreakdownCard(
          categoryTotals: [
            _totals(1).single,
            const CategoryTotal(
              categoryId: 'category-empty',
              name: 'Empty',
              expenseMinorUnits: 0,
            ),
            const CategoryTotal(
              categoryId: 'category-2',
              name: 'Category 2',
              expenseMinorUnits: 1000,
            ),
          ],
        ),
      ),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    final palette = slicePaletteFor(Brightness.light);
    expect(canvas.arcs, hasLength(2));
    expect(canvas.arcs[0].paint.color.toARGB32(), palette[0].toARGB32());
    expect(canvas.arcs[1].paint.color.toARGB32(), palette[2].toARGB32());
    // The second visible arc starts where the zero slice's slot would
    // have begun, so the legend colors and ring angles stay aligned.
    expect(canvas.arcs[1].startAngle, closeTo(-math.pi / 2 + math.pi, 1e-9));
  });
}
