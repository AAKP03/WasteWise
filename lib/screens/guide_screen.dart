
import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  final String categoryName;

  const GuideScreen({
    super.key,
    required this.categoryName,
  });

  static const Map<String, List<String>> disposalGuides = {
    'Electronics': [
      'Do not throw electronic devices into general waste.',
      'Remove personal information from devices before recycling.',
      'Take old electronics to an authorized e-waste collection center.',
      'Reuse, repair, or donate working electronic devices.',
    ],
    'Batteries': [
      'Do not dispose of batteries in ordinary household waste.',
      'Keep damaged or leaking batteries away from other waste.',
      'Cover exposed terminals of lithium batteries with non-conductive tape.',
      'Take used batteries to an appropriate battery collection point.',
    ],
    'Plastic': [
      'Separate recyclable plastics from other household waste.',
      'Empty and clean plastic containers before recycling.',
      'Check local recycling rules for accepted plastic types.',
      'Reduce single-use plastics and reuse containers when possible.',
    ],
    'Clothing': [
      'Donate clean clothes that are still in good condition.',
      'Repair damaged clothing whenever possible.',
      'Reuse old fabric for cleaning or other household purposes.',
      'Take unusable textiles to a textile recycling facility where available.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final instructions = disposalGuides[categoryName] ?? [
      'No disposal guidance is currently available.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disposal Guide'),
        backgroundColor: Colors.green.shade100,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.eco,
            size: 60,
            color: Colors.green.shade700,
          ),

          const SizedBox(height: 16),

          Text(
            categoryName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Disposal Guidance',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...instructions.asMap().entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
