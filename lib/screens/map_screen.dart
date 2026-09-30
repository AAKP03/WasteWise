import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final disposalPoints = [
      {
        'name': 'GreenKeepers (Pvt) Ltd',
        'address': '115, 6 Rosmead Pl, Colombo',
        'category': 'Clothing',
        'distance': '1.2 km',
      },
      {
        'name': 'The Salvation Army',
        'address': 'Union Place, Colombo',
        'category': 'Clothing',
        'distance': '2.0 km',
      },
      {
        'name': 'Central Recycling Point',
        'address': 'Colombo',
        'category': 'Electronics',
        'distance': '2.8 km',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('Nearby Disposal Points'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 230,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 70, color: Colors.green),
                      SizedBox(height: 10),
                      Text(
                        'Map Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Real GPS map will be connected later',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const Positioned(
                  top: 35,
                  left: 45,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 35),
                ),

                const Positioned(
                  top: 65,
                  right: 55,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 35),
                ),

                const Positioned(
                  bottom: 35,
                  left: 140,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 35),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Nearby Locations',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: disposalPoints.length,
              itemBuilder: (context, index) {
                final point = disposalPoints[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        point['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),

                          Text(point['address']!),

                          const SizedBox(height: 5),

                          Text(
                            point['category']!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      trailing: Text(
                        point['distance']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
