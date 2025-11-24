import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

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

  Future<Position> getCurrentLocation() async {
    bool hasPermission = await checkPermissions();

    if (!hasPermission) {
      throw Exception(
        'Location permissions are denied. Please enable location access in settings.',
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, 
        timeLimit: const Duration(seconds: 60), 
        forceAndroidLocationManager: false, 
      );
      return position;
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'th_TH', 
      );

      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      Placemark? bestPlace;
      for (Placemark place in placemarks) {
        if (place.street != null && place.street!.isNotEmpty) {
          bestPlace = place;
          break;
        }
      }
      
      bestPlace ??= placemarks[0];

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
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

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

  Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}
