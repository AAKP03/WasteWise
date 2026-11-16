import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wastewise/data/db_helper.dart';
import 'package:wastewise/screens/points_screen.dart';

void main() {
  Future<void> open(WidgetTester tester, _PointsDatabase database) async {
    await tester.pumpWidget(
      MaterialApp(home: PointsScreen(database: database)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startDisposal(WidgetTester tester) async {
    final button = find.text('Mark as Disposed');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('empty log shows zero and no sample activities', (tester) async {
    await open(tester, _PointsDatabase());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Current points: 0'), findsOneWidget);
    expect(find.text('120'), findsNothing);
    expect(find.text('No disposals recorded yet.'), findsOneWidget);
    expect(find.text('Electronics Recycled'), findsNothing);
  });

  testWidgets('reads persisted total and newest-first activity', (
    tester,
  ) async {
    final db = _PointsDatabase()
      ..rows.addAll([_entry('Plastic', 15), _entry('Electronics', 50)]);
    await open(tester, db);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('65 / 200'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
  });

  for (final entry in ecoPointsPerCategory.entries) {
    testWidgets('confirmed ${entry.key} uses team reward and refreshes', (
      tester,
    ) async {
      final db = _PointsDatabase();
      await open(tester, db);
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${entry.key} (+${entry.value} points)').last);
      await tester.pumpAndSettle();
      await startDisposal(tester);
      expect(db.writes, 0);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(db.writes, 1);
      expect(db.rows.single['category_name'], entry.key);
      expect(find.text('Current points: ${entry.value}'), findsOneWidget);
      expect(find.text('+${entry.value}'), findsOneWidget);
    });
  }

  testWidgets('cancelling confirmation writes nothing', (tester) async {
    final db = _PointsDatabase();
    await open(tester, db);
    await startDisposal(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(db.writes, 0);
    expect(db.rows, isEmpty);
  });

  testWidgets('read failure offers retry rather than a fake balance', (
    tester,
  ) async {
    final db = _PointsDatabase()..failRead = true;
    await open(tester, db);
    expect(
      find.text('Could not load Eco Points. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Current points: 0'), findsNothing);
    db.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Current points: 0'), findsOneWidget);
  });

  testWidgets('failed disposal does not add points', (tester) async {
    final db = _PointsDatabase()..failWrite = true;
    await open(tester, db);
    await startDisposal(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(db.rows, isEmpty);
    expect(
      find.text('Could not record disposal. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('refresh failure after save does not repeat the disposal', (
    tester,
  ) async {
    final db = _PointsDatabase()..failReadAfterWrite = true;
    await open(tester, db);
    await startDisposal(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(db.writes, 1);
    expect(
      find.text('Disposal saved. Refresh to load your updated balance.'),
      findsOneWidget,
    );
    db.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(db.writes, 1);
    expect(find.text('Current points: 50'), findsOneWidget);
  });
}

Map<String, dynamic> _entry(String category, int points) => {
  'category_name': category,
  'points_earned': points,
  'disposed_at': '2026-11-16T09:00:00',
};

class _PointsDatabase extends Fake implements DBHelper {
  final List<Map<String, dynamic>> rows = [];
  int writes = 0;
  bool failRead = false;
  bool failWrite = false;
  bool failReadAfterWrite = false;

  @override
  Future<int> getTotalEcoPoints() async {
    if (failRead) throw StateError('Simulated read failure');
    return rows.fold<int>(
      0,
      (total, row) => total + (row['points_earned'] as int),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getEcoPointsLog() async {
    if (failRead) throw StateError('Simulated read failure');
    return List.of(rows);
  }

  @override
  Future<int> addEcoPoints(String categoryName) async {
    if (failWrite) throw StateError('Simulated write failure');
    final earned = ecoPointsPerCategory[categoryName]!;
    rows.insert(0, _entry(categoryName, earned));
    writes++;
    if (failReadAfterWrite) failRead = true;
    return earned;
  }
}
