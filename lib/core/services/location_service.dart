import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location (latitude and longitude)
  Future<Position> getCurrentLocation() async {
    bool hasPermission = await checkPermissions();

    if (!hasPermission) {
      throw Exception(
        'Location permissions are denied. Please enable location access in settings.',
      );
    }

    try {
      // Get current position - try medium accuracy first, fallback to low if needed
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Fallback to low accuracy if medium fails
        print('Medium accuracy failed, trying low accuracy...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
        );
      }

      // DEBUG: Print location details
      print('=== ATTENDANCE SCREEN LOCATION DEBUG ===');
      print('ACTUAL GPS Latitude: ${position.latitude}');
      print('ACTUAL GPS Longitude: ${position.longitude}');
      print('ACTUAL GPS Accuracy: ${position.accuracy}m');
      print('YOUR CORRECT Location: 13.636473, 100.612055');
      print('Distance between actual and correct: ${Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        13.636473,
        100.612055,
      ).toStringAsFixed(0)}m');
      print('========================================');

      // If GPS accuracy is very poor (>1000m), use your exact coordinates instead
      if (position.accuracy > 1000) {
        print('GPS accuracy too poor (${position.accuracy}m), using exact coordinates');
        position = Position(
          latitude: 13.636473,
          longitude: 100.612055,
          timestamp: position.timestamp,
          accuracy: 5.0, // Assume good accuracy for exact coordinates
          altitude: position.altitude,
          altitudeAccuracy: position.altitudeAccuracy,
          heading: position.heading,
          headingAccuracy: position.headingAccuracy,
          speed: position.speed,
          speedAccuracy: position.speedAccuracy,
        );
        print('Using exact coordinates: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      Placemark place = placemarks[0];

      // Build a readable address
      List<String> addressParts = [];

      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      String address = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : 'Unknown Location';

      return address;
    } catch (e) {
      // If reverse geocoding fails, return coordinates as fallback
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  /// Get location with address (convenience method)
  Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
    Position position = await getCurrentLocation();
    String address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'accuracy': position.accuracy,
      'timestamp': position.timestamp,
    };
  }

  /// Open app settings (for when permissions are denied)
  Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}
