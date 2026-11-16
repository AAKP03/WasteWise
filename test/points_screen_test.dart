import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wastewise/data/db_helper.dart';
import 'package:wastewise/models/disposal_point.dart';
import 'package:wastewise/screens/map_screen.dart';
import 'package:wastewise/screens/points_screen.dart';

const _mapTab = Key('test-map-tab');
const _pointsTab = Key('test-points-tab');
const _pointName = 'Test disposal point';

void main() {
  Future<void> open(WidgetTester tester, _PointsDatabase database) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_ScreenHarness(database: database));
    await tester.pumpAndSettle();
  }

  Finder pageScroll(Type screen) => find
      .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
      .first;

  Future<void> showActivity(WidgetTester tester, String award) async {
    await tester.scrollUntilVisible(
      find.text(award),
      250,
      scrollable: pageScroll(PointsScreen),
    );
    await tester.ensureVisible(find.text(award));
    await tester.pumpAndSettle();
  }

  Future<void> startDisposal(
    WidgetTester tester, {
    String category = 'Electronics',
    bool confirmDialog = true,
  }) async {
    await tester.tap(find.byKey(_mapTab));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(_pointName),
      250,
      scrollable: pageScroll(MapScreen),
    );
    await tester.ensureVisible(find.text(_pointName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_pointName));
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(wasteCategoryLabel(category)).last);
    await tester.pumpAndSettle();

    final button = find.text('Mark as disposed');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    if (confirmDialog) {
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Confirm disposal'), findsOneWidget);
    }
  }

  Future<void> showPoints(WidgetTester tester) async {
    await tester.tap(find.byKey(_pointsTab));
    await tester.pumpAndSettle();
  }

  testWidgets('empty log shows zero and no sample activities', (tester) async {
    await open(tester, _PointsDatabase());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Current points: 0'), findsOneWidget);
    expect(find.text('120'), findsNothing);
    expect(find.text('No activity yet'), findsOneWidget);
    expect(find.text('Electronics Recycled'), findsNothing);
  });

  testWidgets('reads persisted total and newest-first activity', (
    tester,
  ) async {
    final db = _PointsDatabase()
      ..rows.addAll([
        _entry('Plastic', 15),
        _entry('Electronics', 50, date: '2026-11-15T09:00:00'),
      ]);
    await open(tester, db);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('65 / 200'), findsOneWidget);
    await showActivity(tester, '+15');
    expect(find.text(wasteCategoryLabel('Plastic')), findsOneWidget);
    await showActivity(tester, '+50');
    expect(find.text(wasteCategoryLabel('Electronics')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('+15')).dy,
      lessThan(tester.getTopLeft(find.text('+50')).dy),
    );
  });

  for (final entry in ecoPointsPerCategory.entries) {
    testWidgets('confirmed ${entry.key} uses team reward and refreshes', (
      tester,
    ) async {
      final db = _PointsDatabase();
      await open(tester, db);
      await startDisposal(tester, category: entry.key);
      expect(db.calls, 0);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(db.calls, 1);
      expect(db.rows.single['category_name'], entry.key);
      expect(find.text('+${entry.value} Eco Points earned'), findsOneWidget);
      await showPoints(tester);
      expect(find.text('Current points: ${entry.value}'), findsOneWidget);
      await showActivity(tester, '+${entry.value}');
      expect(db.calls, 1);
    });
  }

  testWidgets('cancelling confirmation writes nothing', (tester) async {
    final db = _PointsDatabase();
    await open(tester, db);
    await startDisposal(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(db.calls, 0);
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
    expect(db.calls, 0);
  });

  testWidgets('failed disposal does not add points', (tester) async {
    final db = _PointsDatabase()..failWrite = true;
    await open(tester, db);
    await startDisposal(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(db.calls, 1);
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
    expect(db.calls, 1);
    expect(db.rows, hasLength(1));
    await showPoints(tester);
    expect(
      find.text('Could not load Eco Points. Please try again.'),
      findsOneWidget,
    );
    db.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Current points: 50'), findsOneWidget);
    await showActivity(tester, '+50');
    expect(db.calls, 1);
  });

  testWidgets('double taps and a pending save award points exactly once', (
    tester,
  ) async {
    final gate = Completer<void>();
    final db = _PointsDatabase()..saveGate = gate;
    await open(tester, db);
    await startDisposal(tester, confirmDialog: false);
    // No frame between taps: exercise the synchronous re-entry guard too.
    final actionPosition = tester.getCenter(find.text('Mark as disposed'));
    await tester.tapAt(actionPosition);
    await tester.tapAt(actionPosition);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final confirmPosition = tester.getCenter(find.text('Confirm'));
    await tester.tapAt(confirmPosition);
    await tester.tapAt(confirmPosition);
    await tester.pumpAndSettle();
    expect(db.calls, 1);
    expect(db.rows, isEmpty);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving...'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(db.rows, hasLength(1));
    await showPoints(tester);
    expect(find.text('Current points: 50'), findsOneWidget);
    expect(db.calls, 1);
  });
}

/// Mirrors the real IndexedStack tab flow using the screens' injection points.
class _ScreenHarness extends StatefulWidget {
  const _ScreenHarness({required this.database});
  final _PointsDatabase database;

  @override
  State<_ScreenHarness> createState() => _ScreenHarnessState();
}

class _ScreenHarnessState extends State<_ScreenHarness> {
  int _selected = 1;
  late final List<Widget> _screens = [
    MapScreen(database: widget.database, locationProvider: () async => null),
    PointsScreen(database: widget.database),
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: IndexedStack(index: _selected, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: const [
          NavigationDestination(
            key: _mapTab,
            icon: Icon(Icons.map),
            label: 'Locations',
          ),
          NavigationDestination(
            key: _pointsTab,
            icon: Icon(Icons.eco),
            label: 'Eco Points',
          ),
        ],
      ),
    ),
  );
}

Map<String, dynamic> _entry(
  String category,
  int points, {
  String date = '2026-11-16T09:00:00',
}) => {'category_name': category, 'points_earned': points, 'disposed_at': date};

/// In-memory records only: no SQLite plugin, files, phone, or GPS are used.
class _PointsDatabase extends Fake implements DBHelper {
  final List<Map<String, dynamic>> rows = [];
  int calls = 0;
  bool failRead = false;
  bool failWrite = false;
  bool failReadAfterWrite = false;
  Completer<void>? saveGate;

  @override
  Future<int> getTotalEcoPoints() async {
    if (failRead) throw StateError('Simulated read failure');
    return rows.fold<int>(0, (sum, row) => sum + (row['points_earned'] as int));
  }

  @override
  Future<List<Map<String, dynamic>>> getEcoPointsLog() async {
    if (failRead) throw StateError('Simulated read failure');
    return List.of(rows);
  }

  @override
  Future<List<DisposalPoint>> getDisposalPoints({String? category}) async => [
    DisposalPoint(
      name: _pointName,
      address: 'Test fixture address',
      latitude: 6.9,
      longitude: 79.8,
      categoriesAccepted: ecoPointsPerCategory.keys.toList(),
      source: 'In-memory test fixture',
    ),
  ];

  @override
  Future<int> addEcoPoints(String categoryName) async {
    calls++;
    if (failWrite) throw StateError('Simulated write failure');
    if (saveGate != null) await saveGate!.future;
    final earned = ecoPointsPerCategory[categoryName]!;
    rows.insert(0, _entry(categoryName, earned));
    if (failReadAfterWrite) failRead = true;
    return earned;
  }
}
