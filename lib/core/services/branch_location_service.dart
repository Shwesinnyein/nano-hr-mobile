import 'dart:math';

class BranchLocation {
  final String branchId;
  final String branchName;
  final double latitude;
  final double longitude;

  BranchLocation({
    required this.branchId,
    required this.branchName,
    required this.latitude,
    required this.longitude,
  });
}

class BranchLocationService {
  // Maximum distance (in kilometers) to consider a branch as "nearby"
  // 0.5 km = 500 meters, 1.0 km = 1000 meters, etc.
  // Use 0.060 km (≈60 meters) as the office geofence radius
  static const double maxBranchRadius = 0.060; // 60 meters

  // Optional GPS tolerance (in kilometers) to mitigate indoor jitter
  // e.g. 0.03 km = 30 meters
  static const double gpsTolerance = 0.03;

  // Define your 7 branches with their coordinates
  static final List<BranchLocation> branches = [
    BranchLocation(
      branchId: '001',
      branchName: '001 Branch',
      latitude: 7.839149855783124, // Bangkok coordinates
      longitude: 98.33540445266006,
    ),
    BranchLocation(
      branchId: '002',
      branchName: '002 Branch',
      latitude: 13.636089476141379, // Exact Thepharak coordinates
      longitude: 100.61173308918717,
    ),
    BranchLocation(
      branchId: '003',
      branchName: '003 Branch',
      latitude: 13.863743444884934, // Exact 003 Branch coordinates
      longitude: 100.64715847499053,
    ),
    BranchLocation(
      branchId: '004',
      branchName: '004 Branch',
      latitude: 13.818936475465009, // Exact 004 Branch coordinates
      longitude: 100.6361832130564,
    ),
    BranchLocation(
      branchId: '005',
      branchName: '005 Branch',
      latitude: 13.640392975169945, // Exact 005 Branch coordinates
      longitude: 100.63412340139261,
    ),
    BranchLocation(
      branchId: '006',
      branchName: '006 Branch',
      latitude: 13.796661937791436, // Exact 006 Branch coordinates
      longitude: 100.56788517654206,
    ),
    BranchLocation(
      branchId: '007',
      branchName: '007 Branch',
      latitude: 13.616466965608668, // Exact 007 Branch coordinates
      longitude: 100.70247544055835,
    ),
  ];

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Find the nearest branch to the given coordinates
  /// Returns null if no branch is within maxBranchRadius
  static BranchLocation? findNearestBranch(
    double userLat,
    double userLng, {
    bool enforceRadius = true,
  }) {
    if (branches.isEmpty) return null;

    BranchLocation nearestBranch = branches[0];
    double minDistance = calculateDistance(
      userLat,
      userLng,
      nearestBranch.latitude,
      nearestBranch.longitude,
    );

    for (int i = 1; i < branches.length; i++) {
      final branch = branches[i];
      final distance = calculateDistance(
        userLat,
        userLng,
        branch.latitude,
        branch.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestBranch = branch;
      }
    }

    // Check if nearest branch is within the allowed radius
    if (enforceRadius && minDistance > (maxBranchRadius + gpsTolerance)) {
      return null; // Too far from any branch
    }

    return nearestBranch;
  }

  /// Get branch name for display (just the branch name, no company prefix)
  /// Returns "Unknown Branch" if not within maxBranchRadius
  static String getBranchDisplayName(double userLat, double userLng) {
    final nearestBranch = findNearestBranch(userLat, userLng);
    return nearestBranch?.branchName ?? 'Unknown Branch';
  }

  /// Check if user is within a specific branch radius
  static bool isWithinBranchRadius(double userLat, double userLng) {
    final nearestBranch = findNearestBranch(userLat, userLng);
    return nearestBranch != null;
  }

  /// Get branch info with distance
  static Map<String, dynamic>? getNearestBranchInfo(
    double userLat,
    double userLng,
  ) {
    final nearestBranch = findNearestBranch(userLat, userLng);
    if (nearestBranch == null) return null;

    final distance = calculateDistance(
      userLat,
      userLng,
      nearestBranch.latitude,
      nearestBranch.longitude,
    );

    return {
      'branchId': nearestBranch.branchId,
      'branchName': nearestBranch.branchName,
      'distance': distance,
      'latitude': nearestBranch.latitude,
      'longitude': nearestBranch.longitude,
    };
  }
}
