import 'package:geolocator/geolocator.dart';

class LocationService {
  // Get the current device location.
  static Future<Position?> getCurrentPosition() async {
    // Check whether GPS/location services are enabled.
    final bool gpsEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!gpsEnabled) {
      return null;
    }

    // Check current location permission.
    LocationPermission permission =
        await Geolocator.checkPermission();

    // Request permission only when permission is denied.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If permission is permanently denied, open App Settings.
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    // Stop if permission is still denied.
    if (permission == LocationPermission.denied) {
      return null;
    }

    // Get the current GPS position.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two locations in kilometres.
  static double distanceInKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final double distanceInMeters =
        Geolocator.distanceBetween(
      lat1,
      lng1,
      lat2,
      lng2,
    );

    return distanceInMeters / 1000;
  }
}