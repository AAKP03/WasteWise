import 'package:flutter/material.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'title': 'Electronics Recycled',
        'date': 'Today',
        'points': '+20',
        'icon': Icons.devices,
      },
      {
        'title': 'Battery Recycled',
        'date': 'Yesterday',
        'points': '+10',
        'icon': Icons.battery_full,
      },
      {
        'title': 'Plastic Recycled',
        'date': '2 days ago',
        'points': '+10',
        'icon': Icons.recycling,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('Eco Points'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                child: const Column(
                  children: [
                    Icon(Icons.eco, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      '120',
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

              const SizedBox(height: 30),

              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = activities[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(item['date'] as String),
                      trailing: Text(
                        item['points'] as String,
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
