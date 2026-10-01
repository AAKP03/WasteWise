import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../data/disposal_points_seed.dart' as seed;
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

  // Real disposal points from seed data (with GPS coordinates)
  final List<DisposalPoint> disposalPoints = seed.disposalPoints;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        if (position == null) {
          _errorMessage = 'Could not get location. Check GPS and permissions.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
            // ── Real OpenStreetMap (top section) ──────────────────────────
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

            // ── Nearby Locations heading ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Nearby Locations',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // ── Disposal points list (from feature/points-ui) ──────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: disposalPoints.length,
                itemBuilder: (context, index) {
                  final point = disposalPoints[index];
                  // Calculate distance if we have user location
                  String distanceLabel = '';
                  if (_currentPosition != null) {
                    final km = LocationService.distanceInKm(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      point.latitude,
                      point.longitude,
                    );
                    distanceLabel = '${km.toStringAsFixed(1)} km';
                  }
                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.green.shade50),
                    ),
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
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ...point.categoriesAccepted.map(
                                      (cat) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (distanceLabel.isNotEmpty)
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
                                            distanceLabel,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return Container(
        color: Colors.green.shade50,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 10),
              Text('Getting your location…',
                  style: TextStyle(color: Colors.green)),
            ],
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
              const Icon(Icons.location_off, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchLocation();
                },
                icon: const Icon(Icons.refresh, color: Colors.green),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.green)),
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.wastewise',
        ),
        MarkerLayer(
          markers: [
            // User location marker
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
                point: LatLng(point.latitude, point.longitude),
                width: 36,
                height: 36,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.green,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}