
import 'package:flutter/material.dart';
import 'guide_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  // Shared category data
  // GuideScreen can access CategoryScreen.categories
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
  State<CategoryScreen> createState() =>
      _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // Search text controller
  final TextEditingController _searchController =
      TextEditingController();

  // Waste items and their disposal instructions
  static const Map<String, Map<String, String>> wasteItems = {
    'phone': {
      'category': 'Electronics',
      'message':
          'Remove your personal data and take your phone '
          'to an authorized e-waste collection center.',
    },
    'mobile': {
      'category': 'Electronics',
      'message':
          'Remove personal data and recycle your mobile '
          'phone through an authorized e-waste collector.',
    },
    'smartphone': {
      'category': 'Electronics',
      'message':
          'Back up and erase personal data, then take '
          'the phone to an e-waste collection center.',
    },
    'charger': {
      'category': 'Electronics',
      'message':
          'Take your old charger to an authorized '
          'e-waste collection center.',
    },
    'cable': {
      'category': 'Electronics',
      'message':
          'Take unused electronic cables to an '
          'appropriate e-waste collection center.',
    },
    'laptop': {
      'category': 'Electronics',
      'message':
          'Back up and securely erase personal data. '
          'Donate working laptops or use an e-waste collector.',
    },
    'shoes': {
      'category': 'Clothing',
      'message':
          'Donate or reuse shoes that are still in good '
          'condition. Check for footwear recycling options '
          'for damaged shoes.',
    },
    'shoe': {
      'category': 'Clothing',
      'message':
          'Donate reusable shoes or find a suitable '
          'footwear recycling program.',
    },
    'shirt': {
      'category': 'Clothing',
      'message':
          'Donate or reuse shirts in good condition. '
          'Use a textile collection for damaged items.',
    },
    'clothes': {
      'category': 'Clothing',
      'message':
          'Donate clean, reusable clothes. Consider '
          'textile recycling for unusable clothing.',
    },
    'jeans': {
      'category': 'Clothing',
      'message':
          'Repair, reuse, or donate jeans. Check for '
          'textile recycling options for damaged jeans.',
    },
    'battery': {
      'category': 'Batteries',
      'message':
          'Take used batteries to a designated battery '
          'collection point. Do not put them in household waste.',
    },
    'batteries': {
      'category': 'Batteries',
      'message':
          'Store used batteries safely and take them '
          'to a designated battery collection point.',
    },
    'power bank': {
      'category': 'Batteries',
      'message':
          'Take an old power bank to a collection point '
          'that accepts rechargeable batteries or e-waste.',
    },
    'plastic bottle': {
      'category': 'Plastic',
      'message':
          'Empty and clean the plastic bottle. Place it '
          'in a recycling collection if accepted locally.',
    },
    'bottle': {
      'category': 'Plastic',
      'message':
          'If it is a recyclable plastic bottle, empty '
          'and clean it before recycling.',
    },
    'plastic container': {
      'category': 'Plastic',
      'message':
          'Empty and clean the container. Check whether '
          'your local recycler accepts its plastic type.',
    },
  };

  // Search function
  void _searchWaste() {
    final searchText =
        _searchController.text.trim().toLowerCase();

    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a waste item.'),
        ),
      );
      return;
    }

    final result = wasteItems[searchText];

    if (result == null) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Item Not Found'),
          content: const Text(
            'Sorry, this item is not in our database yet. '
            'Please try another item or browse the categories.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final categoryName = result['category']!;
    final disposalMessage = result['message']!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Category: $categoryName'),
        content: Text(disposalMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuideScreen(
                    categoryName: categoryName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Full Guide'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            final cardWidth =
                (constraints.maxWidth - 36) / 2;

            final cardHeight =
                (cardWidth * 0.95).clamp(145.0, 180.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                      12, 16, 12, 8,
                    ),
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
                                'Choose a waste category or search '
                                'for an item to learn how to dispose '
                                'of it responsibly.',
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

                  // Search section heading
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Find Your Waste Item',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction:
                                TextInputAction.search,
                            onSubmitted: (_) => _searchWaste(),
                            decoration: InputDecoration(
                              hintText:
                                  'Search phone, shoes, battery...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF2E7D32),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFC8E6C9),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _searchWaste,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                          ),
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ),

                  // Category heading
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Explore Waste Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),

                  // Category cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
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
                    itemCount:
                        CategoryScreen.categories.length,
                    itemBuilder: (context, index) {
                      final category =
                          CategoryScreen.categories[index];

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
                                builder: (context) =>
                                    GuideScreen(
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
                                  padding:
                                      const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (category['color']
                                            as Color)
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    size: 30,
                                    color:
                                        category['color'] as Color,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  category['name'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
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
                                  overflow:
                                      TextOverflow.ellipsis,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
