import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Electronics',
        'icon': Icons.devices,
      },
      {
        'name': 'Batteries',
        'icon': Icons.battery_full,
      },
      {
        'name': 'Plastic',
        'icon': Icons.recycling,
      },
      {
        'name': 'Clothing',
        'icon': Icons.checkroom,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return Card(
              child: InkWell(
                onTap: () {
                  debugPrint('${category['name']} selected');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 50,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
