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
      // Try multiple times with different accuracy settings
      Position? bestPosition;
      double bestAccuracy = double.infinity;
      
      // First attempt: Best accuracy with longer timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 30),
        );
        if (position.accuracy < bestAccuracy) {
          bestPosition = position;
          bestAccuracy = position.accuracy;
        }
      } catch (e) {
        print('First attempt failed: $e');
      }
      
      // Second attempt: High accuracy with medium timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        if (position.accuracy < bestAccuracy) {
          bestPosition = position;
          bestAccuracy = position.accuracy;
        }
      } catch (e) {
        print('Second attempt failed: $e');
      }
      
      // Third attempt: Medium accuracy with short timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        if (position.accuracy < bestAccuracy) {
          bestPosition = position;
          bestAccuracy = position.accuracy;
        }
      } catch (e) {
        print('Third attempt failed: $e');
      }
      
      if (bestPosition != null) {
        print('Best location accuracy: ${bestPosition.accuracy}m');
        return bestPosition;
      } else {
        throw Exception('All location attempts failed');
      }
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
