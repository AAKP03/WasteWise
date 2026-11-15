import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../data/db_helper.dart';
import '../models/disposal_point.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;

  final MapController _mapController = MapController();

  List<DisposalPoint> disposalPoints = [];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  // Get current location and disposal points
  Future<void> _fetchLocation() async {
    try {
      final points = await DBHelper().getDisposalPoints();

      final position = await LocationService.getCurrentPosition();

      // Sort nearest disposal points first
      if (position != null) {
        points.sort((a, b) {
          final distanceA = LocationService.distanceInKm(
            position.latitude,
            position.longitude,
            a.latitude,
            a.longitude,
          );

          final distanceB = LocationService.distanceInKm(
            position.latitude,
            position.longitude,
            b.latitude,
            b.longitude,
          );

          return distanceA.compareTo(distanceB);
        });
      }

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        disposalPoints = points;
        _isLoading = false;

        _errorMessage = position == null
            ? 'Could not get location. Check GPS and permissions.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  // Calculate distance from current location
  String _getDistance(DisposalPoint point) {
    if (_currentPosition == null) {
      return 'Distance unavailable';
    }

    final km = LocationService.distanceInKm(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      point.latitude,
      point.longitude,
    );

    return '${km.toStringAsFixed(1)} km';
  }

  // Open Google Maps with the selected disposal point
  Future<void> _openDirections(DisposalPoint point) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${point.latitude},${point.longitude}'
      '&travelmode=driving',
    );

    try {
      final bool launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening directions.'),
        ),
      );
    }
  }

  // Show disposal point details when marker or list item is tapped
  void _showPointDetails(DisposalPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom sheet handle
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Disposal point name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Address
                const Text(
                  'Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  point.address,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 18),

                // Accepted waste categories
                const Text(
                  'Accepted Waste Categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: point.categoriesAccepted.map((category) {
                    return Chip(
                      label: Text(category),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Distance information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.near_me,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Distance: ${_getDistance(point)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Google Maps directions button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openDirections(point);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),

      appBar: AppBar(
        title: const Text('Nearby Disposal Points'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map section
            Container(
              width: double.infinity,
              height: 230,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildMap(),
              ),
            ),

            // Nearby locations heading
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Nearby Locations',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Disposal points list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: disposalPoints.length,
                itemBuilder: (context, index) {
                  final point = disposalPoints[index];

                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showPointDetails(point),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 26,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    point.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    point.address,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...point.categoriesAccepted.map(
                                        (category) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me,
                                            size: 16,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getDistance(point),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
        ),
      ),

      // Current location button
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: () {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  15.0,
                );
              },
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  // Build OpenStreetMap
  Widget _buildMap() {
    if (_isLoading) {
      return Container(
        color: Colors.green.shade50,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.green.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 48,
                color: Colors.red,
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _fetchLocation();
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.green,
                ),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return FlutterMap(
      mapController: _mapController,

      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 15.0,
      ),

      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.wastewise',
        ),

        // User and disposal point markers
        MarkerLayer(
          markers: [
            // Current user location
            Marker(
              point: userLatLng,
              width: 48,
              height: 48,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 40,
              ),
            ),

            // Disposal point markers
            ...disposalPoints.map(
              (point) => Marker(
                point: LatLng(
                  point.latitude,
                  point.longitude,
                ),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () {
                    _showPointDetails(point);
                  },
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}