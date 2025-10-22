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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // Highest possible accuracy
        timeLimit: const Duration(seconds: 60), // Even longer timeout for best accuracy
        forceAndroidLocationManager: false, // Use FusedLocationProvider
      );
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
      // Try multiple geocoding attempts for better accuracy
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'th_TH', // Use Thai locale for better accuracy in Thailand
      );

      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      // Try to find the most accurate placemark
      Placemark? bestPlace;
      for (Placemark place in placemarks) {
        // Prefer placemarks with street information
        if (place.street != null && place.street!.isNotEmpty) {
          bestPlace = place;
          break;
        }
      }
      
      // If no street found, use the first one
      bestPlace ??= placemarks[0];

      // Build a readable address with more detail
      List<String> addressParts = [];

      if (bestPlace.street != null && bestPlace.street!.isNotEmpty) {
        addressParts.add(bestPlace.street!);
      }
      if (bestPlace.subLocality != null && bestPlace.subLocality!.isNotEmpty) {
        addressParts.add(bestPlace.subLocality!);
      }
      if (bestPlace.locality != null && bestPlace.locality!.isNotEmpty) {
        addressParts.add(bestPlace.locality!);
      }
      if (bestPlace.administrativeArea != null && bestPlace.administrativeArea!.isNotEmpty) {
        addressParts.add(bestPlace.administrativeArea!);
      }
      if (bestPlace.country != null && bestPlace.country!.isNotEmpty) {
        addressParts.add(bestPlace.country!);
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
