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

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

// The painter is matched by its private runtimeType name; renaming
// _CategoryRingPainter must also update this string.
CustomPainter _ringPainterOf(WidgetTester tester) {
  final paintWidget = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CategoryBreakdownCard),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter?.runtimeType.toString() == '_CategoryRingPainter',
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

  testWidgets('cycles palette colors after six slices with half-palette offset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(8))),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    final palette = slicePaletteFor(Brightness.light);
    expect(canvas.arcs, hasLength(8));
    // Cycle 0 (indices 0-5): palette[0..5]
    // Cycle 1 (indices 6-7): offset by 3 (palette.length ~/ 2)
    //   index 6 -> (6 + 1*3) % 6 = 3 -> palette[3]
    //   index 7 -> (7 + 1*3) % 6 = 4 -> palette[4]
    final expectedIndices = [0, 1, 2, 3, 4, 5, 3, 4];
    for (var index = 0; index < canvas.arcs.length; index++) {
      expect(
        canvas.arcs[index].paint.color.toARGB32(),
        palette[expectedIndices[index]].toARGB32(),
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

  testWidgets('uses shortestSide for radius on non-square canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(2))),
    );
    final canvas = _RecordingCanvas();
    // Non-square: 200 wide, 120 tall -> shortestSide = 120
    _ringPainterOf(tester).paint(canvas, const Size(200, 120));

    // Radius should be (120 - 20) / 2 = 50
    expect(canvas.circles.single.radius, closeTo(50, 1e-9));
    // Center should be at (100, 60) = size/2
    expect(canvas.circles.single.center, const Offset(100, 60));
  });

  testWidgets('paints income metric slices when metric is income', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CategoryBreakdownCard(
          categoryTotals: [
            CategoryTotal(
              categoryId: 'cat-1',
              name: 'Income Cat 1',
              expenseMinorUnits: 0,
              incomeMinorUnits: 2000,
            ),
            CategoryTotal(
              categoryId: 'cat-2',
              name: 'Income Cat 2',
              expenseMinorUnits: 0,
              incomeMinorUnits: 1000,
            ),
          ],
          metric: CategoryBreakdownMetric.income,
        ),
      ),
    );
    final canvas = _RecordingCanvas();
    _ringPainterOf(tester).paint(canvas, const Size(160, 160));

    final palette = slicePaletteFor(Brightness.light);
    expect(canvas.arcs, hasLength(2));
    // Total income = 3000
    // cat-1: 2000/3000 * 2π = 4π/3
    // cat-2: 1000/3000 * 2π = 2π/3
    expect(canvas.arcs[0].sweepAngle, closeTo(4 * math.pi / 3, 1e-9));
    expect(canvas.arcs[1].sweepAngle, closeTo(2 * math.pi / 3, 1e-9));
    for (var index = 0; index < canvas.arcs.length; index++) {
      expect(
        canvas.arcs[index].paint.color.toARGB32(),
        palette[index].toARGB32(),
      );
    }
  });

  testWidgets('shouldRepaint returns true when slices.length changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(2))),
    );
    final painter1 = _ringPainterOf(tester);

    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(3))),
    );
    final painter2 = _ringPainterOf(tester);

    expect(painter2.shouldRepaint(painter1), isTrue);
  });

  testWidgets('shouldRepaint returns false when all properties equal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(2))),
    );
    final painter1 = _ringPainterOf(tester);

    await tester.pumpWidget(
      _wrap(CategoryBreakdownCard(categoryTotals: _totals(2))),
    );
    final painter2 = _ringPainterOf(tester);

    expect(painter2.shouldRepaint(painter1), isFalse);
  });
}
