
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
            final cardWidth = (constraints.maxWidth - 36) / 2;
            final cardHeight =
                (cardWidth * 0.95).clamp(145.0, 180.0).toDouble();

            return Column(
              children: [
                // Welcome banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Small actions. Greener tomorrow.',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Choose a waste category and learn '
                              'how to dispose of it responsibly.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF37634A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8E6C9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.recycling,
                          size: 36,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section heading
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Explore Waste Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),

                // Colorful category cards
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12, 4, 12, 16,
                    ),
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
                                    color:
                                        (category['color'] as Color)
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
                                    color:
                                        category['color'] as Color,
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
