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
  bool _recording = false;
  String? _error;
  String _category = ecoPointsPerCategory.keys.first;

  DBHelper get _database => widget.database ?? DBHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPoints();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_recording) {
      _loadPoints();
    }
  }

  Future<void> _loadPoints() async {
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
    }
  }

  Future<void> _markAsDisposed() async {
    if (_recording || _loading || _error != null) return;
    setState(() => _recording = true);
    final category = _category;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm disposal'),
          content: Text(
            'Have you disposed of this $category item? '
            'Confirm to earn ${ecoPointsPerCategory[category]} Eco Points.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final earned = await _database.addEcoPoints(category);
      if (!mounted) return;
      await _loadPoints();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error == null
                ? 'Disposal recorded. +$earned Eco Points!'
                : 'Disposal saved. Refresh to load your updated balance.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not record disposal. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _recording = false);
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
    final remaining = (_rewardTarget - _total).clamp(0, _rewardTarget);
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
            onPressed: _loading || _recording ? null : _loadPoints,
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
                              value: (_total / _rewardTarget).clamp(0.0, 1.0),
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

                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Record a disposal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Disposed category',
                              ),
                              items: ecoPointsPerCategory.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    '${entry.key} (+${entry.value} points)',
                                  ),
                                );
                              }).toList(),
                              onChanged: _recording
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _category = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _recording ? null : _markAsDisposed,
                              icon: const Icon(Icons.recycling),
                              label: Text(
                                _recording ? 'Saving...' : 'Mark as Disposed',
                              ),
                            ),
                          ],
                        ),
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
                      const Text('No disposals recorded yet.')
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
