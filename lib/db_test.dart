import 'package:flutter/material.dart';

import 'data/db_helper.dart';

void main() => runApp(const MaterialApp(home: DbTestScreen()));

class DbTestScreen extends StatefulWidget {
  const DbTestScreen({super.key});
  @override
  State<DbTestScreen> createState() => _DbTestScreenState();
}

class _DbTestScreenState extends State<DbTestScreen> {
  String result = 'Loading...';

  @override
  void initState() {
    super.initState();
    _run();
  }

  String _check(String label, Object actual, Object expected) {
    final ok = actual == expected;
    return '${ok ? "PASS" : "FAIL"}  $label: $actual (expect $expected)';
  }

  Future<void> _run() async {
    final db = DBHelper();
    final lines = <String>[];

    // ---- Data checks ----
    final categories = await db.getCategories();
    final allPoints = await db.getDisposalPoints();
    final electronics = await db.getDisposalPoints(category: 'Electronics');
    lines.add(_check('Categories', categories.length, 4));
    lines.add(_check('All points', allPoints.length, 18));
    lines.add(_check('Electronics points', electronics.length, 11));

    // ---- Eco points checks ----
    final start = await db.getTotalEcoPoints(); // persistence check
    lines.add('Total at launch: $start  (compare after an app/phone restart)');

    await db.addEcoPoints('Electronics');
    lines.add(
      _check(
        'After +Electronics (50)',
        await db.getTotalEcoPoints(),
        start + 50,
      ),
    );

    lines.add(
      _check('Adjustment -50 returns', await db.addAdjustment(-50), start),
    );

    // Clamp test: try to go below zero, balance must stop at 0.
    lines.add(
      _check(
        'Adjustment below zero is clamped',
        await db.addAdjustment(-(start + 5)),
        0,
      ),
    );

    // Restore the balance so the test leaves the total unchanged.
    lines.add(_check('Restore balance', await db.addAdjustment(start), start));

    final all = await db.getEcoPointsLog();
    final visible = await db.getEcoPointsLogWithoutAdjustments();
    lines.add(
      'Log rows: ${all.length} total, ${visible.length} without adjustments',
    );

    setState(() => result = lines.join('\n\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(result),
      ),
    );
  }
}
