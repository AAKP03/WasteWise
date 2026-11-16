import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wastewise/main.dart';
import 'package:wastewise/screens/map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFactory = databaseFactoryOrNull;
  const gpsChannel = MethodChannel('flutter.baseflow.com/geolocator');
  const sqliteChannel = MethodChannel('com.tekartik.sqflite');

  setUpAll(() {
    databaseFactoryOrNull = databaseFactorySqflitePlugin;
  });
  tearDownAll(() => databaseFactoryOrNull = previousFactory);

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(gpsChannel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return false;
        case 'checkPermission':
        case 'requestPermission':
          return 0;
        default:
          throw UnsupportedError('Unexpected GPS call: ${call.method}');
      }
    });
    // Mock every native SQLite operation. No file/database is opened, including
    // the path passed by DBHelper: this is only a navigation smoke test.
    messenger.setMockMethodCallHandler(sqliteChannel, (call) async {
      switch (call.method) {
        case 'getDatabasesPath':
          return '/test-only-no-file';
        case 'openDatabase':
          return {'id': 1};
        case 'query':
          final sql = (call.arguments as Map)['sql'] as String;
          if (sql.contains('PRAGMA user_version')) {
            return [
              {'user_version': 3},
            ];
          }
          if (sql.contains('SUM(points_earned)')) {
            return [
              {'total': 0},
            ];
          }
          return <Map<String, Object?>>[];
        case 'execute':
        case 'closeDatabase':
        case 'options':
          return null;
        case 'batch':
          return <Object?>[];
        default:
          throw UnsupportedError('Unexpected SQLite call: ${call.method}');
      }
    });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(gpsChannel, null);
    messenger.setMockMethodCallHandler(sqliteChannel, null);
  });

  testWidgets('App shows the three navigation tabs', (tester) async {
    await tester.pumpWidget(const WasteWiseApp());
    await tester.pumpAndSettle();

    final navigation = find.byType(NavigationBar);
    expect(
      find.descendant(of: navigation, matching: find.text('Categories')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Map')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Eco Points')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing Map cancels a pending location timeout', (
    tester,
  ) async {
    final gps = Completer<Position?>();
    await tester.pumpWidget(
      MaterialApp(home: MapScreen(locationProvider: () => gps.future)),
    );
    await tester.pump();
    // No 21-second advance: disposal must cancel the timeout itself.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gps.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
