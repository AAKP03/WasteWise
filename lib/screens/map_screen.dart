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
  String? _locationMessage;
  String? _selectedCategory;
  bool _locating = false;
  bool _mapReady = false;
  bool _savingDisposal = false;
  int _pointsRequest = 0;
  static const _filterCategories = [
    'Electronics',
    'Batteries',
    'Plastic',
    'Clothing',
  ];

  final MapController _mapController = MapController();

  List<DisposalPoint> disposalPoints = [];

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _fetchLocation();
  }

  Future<void> _loadPoints() async {
    final request = ++_pointsRequest;
    setState(() {
      _isLoading = true;
      _mapReady = false;
      _errorMessage = null;
    });
    try {
      final points = await DBHelper().getDisposalPoints(
        category: _selectedCategory,
      );
      if (!mounted || request != _pointsRequest) return;
      _sortByDistance(points);
      setState(() {
        disposalPoints = points;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || request != _pointsRequest) return;
      setState(() {
        disposalPoints = [];
        _errorMessage = 'Could not load disposal points. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    Position? position;
    try {
      position = await LocationService.getCurrentPosition().timeout(
        const Duration(seconds: 20),
      );
    } catch (_) {
      // A location failure must not discard locations loaded from SQLite.
    }
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _locating = false;
      _locationMessage = position == null
          ? 'Location unavailable. You can still browse disposal points; '
                'distances are unavailable.'
          : null;
      _sortByDistance(disposalPoints);
    });
    if (position != null && _mapReady) {
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    }
  }

  void _sortByDistance(List<DisposalPoint> points) {
    final position = _currentPosition;
    if (position == null) return;
    double distance(DisposalPoint point) => LocationService.distanceInKm(
      position.latitude,
      position.longitude,
      point.latitude,
      point.longitude,
    );
    points.sort((a, b) {
      final comparison = distance(a).compareTo(distance(b));
      return comparison != 0 ? comparison : a.name.compareTo(b.name);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening directions.')),
      );
    }
  }

  void _showPointDetails(DisposalPoint point) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DisposalPointDetails(
        point: point,
        distance: _getDistance(point),
        onDirections: () => _openDirections(point),
        onRecord: _recordDisposal,
      ),
    );
  }

  Future<bool> _recordDisposal(String category) async {
    // This lock survives dismissal/reopening of the details sheet.
    if (_savingDisposal) return false;
    _savingDisposal = true;
    var confirmationSent = false;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm disposal'),
          content: Text(
            'Have you disposed of your $category item at this point?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (confirmationSent) return;
                confirmationSent = true;
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (confirmationSent) return;
                confirmationSent = true;
                Navigator.pop(context, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return false;
      final earned = await DBHelper().addEcoPoints(category);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('+$earned Eco Points earned')));
      }
      // PointsScreen refreshes via Visibility.of when its tab is selected.
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not record disposal. Please try again.'),
          ),
        );
      }
      return false;
    } finally {
      _savingDisposal = false;
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [null, ..._filterCategories].map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category ?? 'All'),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          if (_selectedCategory == category) return;
                          setState(() => _selectedCategory = category);
                          _loadPoints();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_locating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Finding your location...'),
              ),
            if (_locationMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(_locationMessage!)),
                    TextButton(
                      onPressed: _locating ? null : _fetchLocation,
                      child: const Text('Retry GPS'),
                    ),
                  ],
                ),
              ),

            // Map section
            Container(
              width: double.infinity,
              height: (MediaQuery.sizeOf(context).height * 0.3).clamp(
                110.0,
                230.0,
              ),
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
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Disposal points list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Text(_errorMessage!, textAlign: TextAlign.center),
                    )
                  : disposalPoints.isEmpty
                  ? const Center(
                      child: Text(
                        'No disposal points found for this category.',
                      ),
                    )
                  : ListView.builder(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                    color:
                                                        Colors.green.shade800,
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
                                                    color:
                                                        Colors.green.shade700,
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
      floatingActionButton: _currentPosition != null && _mapReady
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

  // Build OpenStreetMap
  Widget _buildMap() {
    if (_isLoading) {
      return Container(
        color: Colors.green.shade50,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.green),
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

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadPoints();
                },
                icon: const Icon(Icons.refresh, color: Colors.green),
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

    final position = _currentPosition;
    final userLatLng = position == null
        ? null
        : LatLng(position.latitude, position.longitude);
    // Center on a loaded point when GPS is unavailable. The final fallback
    // is only a Sri Lanka viewport, never a fabricated disposal marker.
    final center =
        userLatLng ??
        (disposalPoints.isEmpty
            ? const LatLng(6.9271, 79.8612)
            : LatLng(
                disposalPoints.first.latitude,
                disposalPoints.first.longitude,
              ));

    return FlutterMap(
      mapController: _mapController,

      options: MapOptions(
        initialCenter: center,
        onMapReady: () {
          if (mounted) setState(() => _mapReady = true);
        },
        initialZoom: 15.0,
      ),

      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.wastewise.wastewise',
        ),

        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),

        // User and disposal point markers
        MarkerLayer(
          markers: [
            // Current user location (only if permission/GPS is available)
            if (userLatLng != null)
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

class _DisposalPointDetails extends StatefulWidget {
  const _DisposalPointDetails({
    required this.point,
    required this.distance,
    required this.onDirections,
    required this.onRecord,
  });

  final DisposalPoint point;
  final String distance;
  final VoidCallback onDirections;
  final Future<bool> Function(String category) onRecord;

  @override
  State<_DisposalPointDetails> createState() => _DisposalPointDetailsState();
}

class _DisposalPointDetailsState extends State<_DisposalPointDetails> {
  late final List<String> _categories = widget.point.categoriesAccepted
      .where(ecoPointsPerCategory.containsKey)
      .toSet()
      .toList();
  late String? _category = _categories.isEmpty ? null : _categories.first;
  bool _saving = false;
  bool _recorded = false;

  Future<void> _markDisposed() async {
    if (_saving || _recorded || _category == null) return;
    setState(() => _saving = true);
    try {
      final recorded = await widget.onRecord(_category!);
      if (mounted) setState(() => _recorded = recorded);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted && _recorded) {
      // Reveal the success SnackBar and prevent a second award from this sheet.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    return PopScope(
      canPop: !_saving,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.location_on, color: Colors.green),
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
                    IconButton(
                      tooltip: 'Close details',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(point.address),
                const SizedBox(height: 18),
                const Text(
                  'Accepted Waste Categories',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: point.categoriesAccepted
                      .map(
                        (category) => Chip(
                          label: Text(category),
                          backgroundColor: Colors.green.shade50,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Distance: ${widget.distance}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Source',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  point.source?.trim().isNotEmpty == true
                      ? point.source!
                      : 'Source not provided',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : widget.onDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_categories.isEmpty)
                  const Text(
                    'No supported reward category is available at this point.',
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Disposed category',
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: _saving || _recorded
                        ? null
                        : (value) {
                            setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving || _recorded || _category == null
                        ? null
                        : _markDisposed,
                    icon: const Icon(Icons.recycling),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : _recorded
                          ? 'Disposal recorded'
                          : 'Mark as disposed',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
