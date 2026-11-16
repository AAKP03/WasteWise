import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../data/db_helper.dart';
import '../models/disposal_point.dart';
import 'points_screen.dart' show WasteWiseStatusCard, wasteCategoryLabel;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.database, this.locationProvider});

  final DBHelper? database;
  final Future<Position?> Function()? locationProvider;

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
  int _tileGeneration = 0;
  bool _tilesLoading = true;
  bool _tilesSlow = false;
  bool _tileStateScheduled = false;

  final Set<String> _failedTiles = {};

  Timer? _tileTimer;
  Timer? _locationTimer;
  Completer<Position?>? _locationWaiter;

  DBHelper get _database => widget.database ?? DBHelper();

  static const _filterCategories = [
    'Electronics',
    'Batteries',
    'Plastic',
    'Clothing',
  ];

  final MapController _mapController = MapController();

  List<DisposalPoint> disposalPoints = [];

  // Do not request GPS permission automatically when the screen opens.
  @override
  void initState() {
    super.initState();

    _locationMessage =
        'Location access is needed to show your current location. '
        'Tap Retry GPS to allow access.';

    _loadPoints();
  }

  // Load disposal points from the database.
  Future<void> _loadPoints() async {
    final request = ++_pointsRequest;

    _tileTimer?.cancel();

    setState(() {
      _isLoading = true;
      _mapReady = false;
      _tileGeneration++;
      _failedTiles.clear();
      _tilesSlow = false;
      _tilesLoading = true;
      _errorMessage = null;
    });

    try {
      final points = await _database
          .getDisposalPoints(category: _selectedCategory)
          .timeout(const Duration(seconds: 20));

      if (!mounted || request != _pointsRequest) return;

      _sortByDistance(points);

      setState(() {
        disposalPoints = points;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _pointsRequest) return;

      setState(() {
        disposalPoints = [];

        _errorMessage = error is TimeoutException
            ? 'Loading disposal points is taking longer than expected. Please retry.'
            : 'Could not load disposal points. Please try again.';

        _isLoading = false;
      });
    }
  }

  // Location request with a 20-second timeout.
  Future<Position?> _locationWithTimeout() {
    final waiter = Completer<Position?>();

    _locationWaiter = waiter;

    final timer = Timer(const Duration(seconds: 20), () {
      if (!waiter.isCompleted) {
        waiter.completeError(
          TimeoutException('Location request timed out.'),
        );
      }
    });

    _locationTimer = timer;

    Future<Position?>.sync(
      widget.locationProvider ?? LocationService.getCurrentPosition,
    ).then(
      (position) {
        if (!waiter.isCompleted) {
          waiter.complete(position);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!waiter.isCompleted) {
          waiter.completeError(error, stack);
        }
      },
    );

    return waiter.future.whenComplete(() {
      timer.cancel();

      if (identical(_locationTimer, timer)) {
        _locationTimer = null;
      }

      if (identical(_locationWaiter, waiter)) {
        _locationWaiter = null;
      }
    });
  }

  // Request current location only when the user taps Retry GPS.
  Future<void> _fetchLocation() async {
    if (!mounted || _locating) return;

    setState(() {
      _locating = true;
      _locationMessage = null;
    });

    Position? position;
    String? message;

    try {
      position = await _locationWithTimeout();

      if (!mounted) return;

      if (position == null) {
        message =
            'Location unavailable. You can still browse points without distances.';

        if (widget.locationProvider == null) {
          final enabled = await Geolocator.isLocationServiceEnabled().timeout(
            const Duration(seconds: 3),
          );

          if (!enabled) {
            message =
                'GPS is off. Turn on location in phone Settings, then retry. '
                'The location list is still available.';
          } else {
            final permission = await Geolocator.checkPermission().timeout(
              const Duration(seconds: 3),
            );

            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              message =
                  'Location permission is denied. Allow it in phone Settings, '
                  'then retry. You can still browse points without distances.';
            }
          }
        }
      }
    } on TimeoutException {
      message =
          'Finding your location is taking longer than expected. '
          'Retry GPS; you can still browse the location list.';
    } catch (_) {
      message =
          'Could not get your location. Check GPS and permissions, then retry. '
          'The location list is still available.';
    }

    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _locating = false;
      _locationMessage = message;

      _sortByDistance(disposalPoints);
    });

    if (position != null && _mapReady) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15,
      );
    }
  }

  // Sort disposal points by nearest distance.
  void _sortByDistance(List<DisposalPoint> points) {
    final position = _currentPosition;

    if (position == null) return;

    double distance(DisposalPoint point) =>
        LocationService.distanceInKm(
          position.latitude,
          position.longitude,
          point.latitude,
          point.longitude,
        );

    points.sort((a, b) {
      final comparison = distance(a).compareTo(distance(b));

      return comparison != 0
          ? comparison
          : a.name.compareTo(b.name);
    });
  }

  @override
  void dispose() {
    _tileTimer?.cancel();
    _locationTimer?.cancel();

    final waiter = _locationWaiter;

    if (waiter != null && !waiter.isCompleted) {
      waiter.complete(null);
    }

    _mapController.dispose();

    super.dispose();
  }

  // Schedule map tile state updates.
  void _scheduleTileState() {
    if (_tileStateScheduled) return;

    _tileStateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tileStateScheduled = false;

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _tileSucceeded(TileImage tile, int generation) {
    if (!mounted ||
        generation != _tileGeneration ||
        tile.loadError ||
        tile.loadFinishedAt == null) {
      return;
    }

    final changed = _tilesLoading ||
        _tilesSlow ||
        _failedTiles.contains(tile.coordinates.toString());

    _tileTimer?.cancel();

    _tilesLoading = false;
    _tilesSlow = false;

    _failedTiles.remove(tile.coordinates.toString());

    if (changed) {
      _scheduleTileState();
    }
  }

  void _tileFailed(TileImage tile, int generation) {
    if (!mounted || generation != _tileGeneration) return;

    _tileTimer?.cancel();

    _tilesLoading = false;

    if (_failedTiles.add(tile.coordinates.toString())) {
      _scheduleTileState();
    }
  }

  void _startTileTimer() {
    _tileTimer?.cancel();

    if (!_tilesLoading) return;

    _tileTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted || !_tilesLoading) return;

      setState(() {
        _tilesLoading = false;
        _tilesSlow = true;
      });
    });
  }

  void _retryTiles() {
    setState(() {
      _tileGeneration++;
      _failedTiles.clear();
      _tilesSlow = false;
      _tilesLoading = true;
    });

    _startTileTimer();
  }

  // Calculate distance from current location.
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

  // Open Google Maps with the selected disposal point.
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

  // Show disposal point details.
  void _showPointDetails(DisposalPoint point) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _DisposalPointDetails(
        point: point,
        distance: _getDistance(point),
        onDirections: () => _openDirections(point),
        onRecord: _recordDisposal,
      ),
    );
  }

  // Record disposal and award Eco Points.
  Future<bool> _recordDisposal(String category) async {
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

      final earned = await _database.addEcoPoints(category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$earned Eco Points earned'),
          ),
        );
      }

      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not record disposal. Please try again.',
            ),
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),

      appBar: AppBar(
        title: const Text(
          'Nearby Disposal Points',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filters.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [null, ..._filterCategories].map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                category == null
                                    ? 'All'
                                    : wasteCategoryLabel(category),
                              ),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                if (_selectedCategory == category) return;

                                setState(() {
                                  _selectedCategory = category;
                                });

                                _loadPoints();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // GPS loading indicator.
                  if (_locating)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            semanticsLabel: 'Finding your location',
                          ),
                          SizedBox(height: 8),
                          Text('Finding your location...'),
                        ],
                      ),
                    ),

                  // GPS status and Retry GPS button.
                  if (_locationMessage != null)
                    WasteWiseStatusCard(
                      icon: Icons.location_off_outlined,
                      message: _locationMessage!,
                      onRetry: _fetchLocation,
                      retryLabel: 'Retry GPS',
                    ),

                  // Map section.
                  Container(
                    width: double.infinity,
                    height: (MediaQuery.sizeOf(context).height * 0.3)
                        .clamp(110.0, 230.0),
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.shade200,
                      ),
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

                  // Map tile status.
                  if (!_isLoading &&
                      _errorMessage == null &&
                      (_tilesLoading ||
                          _tilesSlow ||
                          _failedTiles.isNotEmpty))
                    WasteWiseStatusCard(
                      loading: _tilesLoading && _failedTiles.isEmpty,
                      icon: Icons.cloud_off_outlined,
                      message: _failedTiles.isNotEmpty
                          ? 'Some map tiles could not load. Check your internet connection. '
                              'The location list and saved points are still available.'
                          : _tilesSlow
                              ? 'Map tiles are taking longer than expected. Check your connection and retry.'
                              : 'Loading map tiles...',
                      onRetry: _tilesSlow || _failedTiles.isNotEmpty
                          ? _retryTiles
                          : null,
                      retryLabel: 'Retry map',
                    ),

                  // Nearby locations heading.
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
                ],
              ),
            ),

            // Loading state.
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: WasteWiseStatusCard(
                  loading: true,
                  message: 'Loading disposal points...',
                ),
              )

            // Database error.
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: WasteWiseStatusCard(
                  icon: Icons.error_outline,
                  message: _errorMessage!,
                  onRetry: _loadPoints,
                ),
              )

            // Empty state.
            else if (disposalPoints.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: WasteWiseStatusCard(
                  icon: Icons.location_searching,
                  message: 'No disposal points found for this category.',
                  onRetry: _loadPoints,
                  retryLabel: 'Retry filter',
                ),
              )

            // Disposal point list.
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                                  backgroundColor: const Color(0xFFEFF6FF),
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
                                                wasteCategoryLabel(category),
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
                                              Flexible(
                                                child: Text(
                                                  _getDistance(point),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade700,
                                                    fontSize: 13,
                                                  ),
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
                    childCount: disposalPoints.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // Current location button.
      floatingActionButton: _currentPosition != null && _mapReady
          ? FloatingActionButton(
              tooltip: 'Center map on your location',
              onPressed: () {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  15.0,
                );
              },
              backgroundColor: colors.primary,
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  // Build OpenStreetMap.
  Widget _buildMap() {
    if (_isLoading) {
      return const WasteWiseStatusCard(
        loading: true,
        message: 'Loading disposal points...',
      );
    }

    if (_errorMessage != null) {
      return const Center(
        child: Icon(
          Icons.map_outlined,
          size: 48,
          semanticLabel: 'Map unavailable while locations could not load',
        ),
      );
    }

    final generation = _tileGeneration;

    final position = _currentPosition;

    final userLatLng = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    // Use a real disposal point as the map center if GPS is unavailable.
    // If no points exist, use Colombo as the initial map viewport.
    final center = userLatLng ??
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
          if (mounted) {
            setState(() => _mapReady = true);
          }

          _startTileTimer();
        },
        initialZoom: 15.0,
      ),

      children: [
        // OpenStreetMap tiles.
        TileLayer(
          key: ValueKey(generation),
          errorTileCallback: (tile, error, stack) {
            _tileFailed(tile, generation);
          },
          tileBuilder: (context, child, tile) {
            _tileSucceeded(tile, generation);
            return child;
          },
          evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.wastewise.wastewise',
        ),

        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),

        // User and disposal point markers.
        MarkerLayer(
          markers: [
            // Current user location, only when GPS is available.
            if (userLatLng != null)
              Marker(
                point: userLatLng,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.my_location,
                  semanticLabel: 'Your current location',
                  color: Colors.blue,
                  size: 40,
                ),
              ),

            // Disposal point markers.
            ...disposalPoints.map(
              (point) => Marker(
                point: LatLng(
                  point.latitude,
                  point.longitude,
                ),
                width: 45,
                height: 45,
                child: IconButton(
                  tooltip: 'Open details for ${point.name}',
                  padding: EdgeInsets.zero,
                  onPressed: () => _showPointDetails(point),
                  icon: const Icon(
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

// Disposal point details bottom sheet.
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
  State<_DisposalPointDetails> createState() =>
      _DisposalPointDetailsState();
}

class _DisposalPointDetailsState
    extends State<_DisposalPointDetails> {
  late final List<String> _categories = widget.point.categoriesAccepted
      .where(ecoPointsPerCategory.containsKey)
      .toSet()
      .toList();

  late String? _category =
      _categories.isEmpty ? null : _categories.first;

  bool _saving = false;
  bool _recorded = false;

  Future<void> _markDisposed() async {
    if (_saving || _recorded || _category == null) return;

    setState(() => _saving = true);

    try {
      final recorded = await widget.onRecord(_category!);

      if (mounted) {
        setState(() => _recorded = recorded);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }

    if (mounted && _recorded) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
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
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
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

                    IconButton(
                      tooltip: 'Close details',
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
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
                          label: Text(wasteCategoryLabel(category)),
                          backgroundColor: Colors.green.shade50,
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 12),

                Text(
                  'Distance: ${widget.distance}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                  ),
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
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
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
                    isExpanded: true,
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Disposed category',
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(wasteCategoryLabel(category)),
                          ),
                        )
                        .toList(),
                    onChanged: _saving || _recorded
                        ? null
                        : (value) {
                            setState(() {
                              _category = value;
                            });
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