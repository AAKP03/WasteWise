import 'package:flutter/material.dart';

import '../data/db_helper.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key, this.database});

  final DBHelper? database;

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with WidgetsBindingObserver {
  static const int _rewardTarget = 200;
  int _total = 0;
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  bool _loadInProgress = false;
  bool _reloadRequested = false;
  bool? _wasVisible;
  String? _error;

  DBHelper get _database => widget.database ?? DBHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // IndexedStack publishes visibility without needing a parent callback.
    final visible = Visibility.of(context);
    final becameVisible = _wasVisible == false && visible;
    _wasVisible = visible;
    if (becameVisible) {
      _loadPoints();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_wasVisible ?? true)) {
      _loadPoints();
    }
  }

  Future<void> _loadPoints() async {
    if (!mounted) return;
    if (_loadInProgress) {
      _reloadRequested = true;
      return;
    }
    _loadInProgress = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final total = await _database.getTotalEcoPoints();
      final activities = await _database.getEcoPointsLog();
      if (!mounted) return;
      setState(() {
        _total = total;
        _activities = activities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Eco Points. Please try again.';
        _loading = false;
      });
    } finally {
      _loadInProgress = false;
      if (_reloadRequested && mounted) {
        _reloadRequested = false;
        await _loadPoints();
      }
    }
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Electronics' => Icons.devices,
      'Batteries' => Icons.battery_full,
      'Clothing' => Icons.checkroom,
      'Plastic' => Icons.recycling,
      _ => Icons.eco,
    };
  }

  String _activityDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Date unavailable';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_rewardTarget - _total).clamp(
      0,
      _rewardTarget > 0 ? _rewardTarget : 0,
    );
    final progress = _rewardTarget > 0
        ? (_total / _rewardTarget).clamp(0.0, 1.0)
        : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('Eco Points'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh points',
            onPressed: _loading ? null : _loadPoints,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadPoints,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.eco, size: 60, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            '$_total',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Eco Points',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keep recycling to earn more points!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress follows the persisted disposal total.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Next Reward',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Current points: $_total',
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Target points: 200',
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$_total / $_rewardTarget',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.green.shade50,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            remaining == 0
                                ? 'Reward target reached!'
                                : 'Earn $remaining more points to unlock your next reward.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (_activities.isEmpty)
                      const Text('No activity yet')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _activities[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  _categoryIcon(
                                    item['category_name'] as String,
                                  ),
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                item['category_name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _activityDate(item['disposed_at'] as String),
                              ),
                              trailing: Text(
                                '+${item['points_earned']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
