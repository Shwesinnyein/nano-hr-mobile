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
  static const double maxBranchRadius = 0.070; 
  static const double gpsTolerance = 0.0;

  static final List<BranchLocation> branches = [
    BranchLocation(
      branchId: '001',
      branchName: '001 Branch',
      latitude: 7.839149855783124, 
      longitude: 98.33540445266006,
    ),
    BranchLocation(
      branchId: '002',
      branchName: '002 Branch',
      latitude: 13.636089476141379, 
      longitude: 100.61173308918717,
    ),
    BranchLocation(
      branchId: '003',
      branchName: '003 Branch',
      latitude: 13.863743444884934, 
      longitude: 100.64715847499053,
    ),
    BranchLocation(
      branchId: '004',
      branchName: '004 Branch',
      latitude: 13.818936475465009, 
      longitude: 100.6361832130564,
    ),
    BranchLocation(
      branchId: '005',
      branchName: '005 Branch',
      latitude: 13.640392975169945, 
      longitude: 100.63412340139261,
    ),
    BranchLocation(
      branchId: '006',
      branchName: '006 Branch',
      latitude: 13.796661937791436, 
      longitude: 100.56788517654206,
    ),
    BranchLocation(
      branchId: '007',
      branchName: '007 Branch',
      latitude: 13.616466965608668, 
      longitude: 100.70247544055835,
    ),
  ];

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; 

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

        return earthRadius * c; 
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

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

    if (enforceRadius && minDistance > (maxBranchRadius + gpsTolerance)) {
      return null; 
    }

    return nearestBranch;
  }

  static String getBranchDisplayName(double userLat, double userLng) {
    final nearestBranch = findNearestBranch(userLat, userLng);
    return nearestBranch?.branchName ?? 'Unknown Branch';
  }

  static bool isWithinBranchRadius(double userLat, double userLng) {
    final nearestBranch = findNearestBranch(userLat, userLng);
    return nearestBranch != null;
  }

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
