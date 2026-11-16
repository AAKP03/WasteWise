
import 'package:flutter/material.dart';
import 'guide_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  static const List<Map<String, dynamic>> categories = [
    {
      'name': 'Electronics',
      'icon': Icons.devices,
      'color': Color(0xFF2563EB),
      'background': Color(0xFFEFF6FF),
      'subtitle': 'Phones, chargers & cables',
    },
    {
      'name': 'Batteries',
      'icon': Icons.battery_charging_full,
      'color': Color(0xFFEA580C),
      'background': Color(0xFFFFF7ED),
      'subtitle': 'Cells & power banks',
    },
    {
      'name': 'Plastic',
      'icon': Icons.recycling,
      'color': Color(0xFF0D9488),
      'background': Color(0xFFF0FDFA),
      'subtitle': 'Bottles & containers',
    },
    {
      'name': 'Clothing',
      'icon': Icons.checkroom,
      'color': Color(0xFF9333EA),
      'background': Color(0xFFFAF5FF),
      'subtitle': 'Clothes & textiles',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Waste Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 44) / 2;
            final cardHeight = (cardWidth * 0.95)
                .clamp(145.0, 180.0)
                .toDouble();

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: cardHeight,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  color: category['background'] as Color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GuideScreen(
                            categoryName:
                                category['name'] as String,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (category['color'] as Color)
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              size: 30,
                              color: category['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: category['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category['subtitle'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
