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

  Future<void> _run() async {
    final db = DBHelper();
    final categories = await db.getCategories();
    final allPoints = await db.getDisposalPoints();
    final electronics = await db.getDisposalPoints(category: 'Electronics');
    await db.addEcoPoints('Electronics');
    final total = await db.getTotalEcoPoints();

    setState(() {
      result = 'Categories: ${categories.length} (expect 4)\n'
          'All points: ${allPoints.length} (expect 18)\n'
          'Electronics points: ${electronics.length} (expect 11)\n'
          'Eco points total: $total (+50 each run)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB test')),
      body: Padding(padding: const EdgeInsets.all(16), child: Text(result)),
    );
  }
}