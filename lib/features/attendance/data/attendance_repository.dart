import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/branch_location_service.dart';
import 'attendance_model.dart';

class AttendanceRepository {
  final AttendanceService _attendanceService;

  AttendanceRepository(this._attendanceService);

  Map<String, String> _getThailandTime() {
    final currentDate = DateTime.now().toUtc().add(const Duration(hours: 7));
    return {
      'date': currentDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'time': currentDate
          .toIso8601String()
          .split('T')[1]
          .split('.')[0], // HH:MM:SS
      'timestamp': currentDate.toIso8601String(), // Full ISO string
    };
  }

  Future<List<Attendance>> listMyAttendance(String userId) async {
    try {
      final response = await _attendanceService.getTodayAttendance(userId);

      final attendanceList = response.map((json) {
        final attendance = Attendance.fromJson(json);

        return attendance;
      }).toList();

      return attendanceList;
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> getAttendanceList(String userId) async {
    try {
      final response = await _attendanceService.getAttendanceList(userId);
      final attendanceList = response.map((json) {
        final attendance = Attendance.fromJson(json);
        return attendance;
      }).toList();

      return attendanceList;
    } catch (e) {
      return [];
    }
  }

  Future<void> checkIn(
    String userId,
    Map<String, dynamic> employeeData, {
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final checkInData = {
        'employeeId': userId,
        'employeeName': employeeData['fullName'] ?? 'Unknown',
        'position': employeeData['positionName'] ?? 'Employee',
        'positionName': employeeData['positionName'] ?? 'Employee',
        'company': employeeData['companyName'] ?? 'NANO-STORES',
        'companyName': employeeData['companyName'] ?? 'NANO-STORES',
        'locationName': address ?? employeeData['locationName'] ?? 'Bangkok',
        'location': address ?? employeeData['locationName'] ?? 'Bangkok',
        'branch': employeeData['branchName'] ?? 'Office',
        'branchName': employeeData['branchName'] ?? 'Office',
        'type': 'checkin',
      };

      // Add GPS coordinates if provided
      if (latitude != null) {
        checkInData['latitude'] = latitude;
      }
      if (longitude != null) {
        checkInData['longitude'] = longitude;
      }
      if (address != null) {
        checkInData['address'] = address;
      }

      // Determine checkInLocation field based on branch proximity
      if (latitude != null && longitude != null) {
        // Check if user is within office range
        final nearestBranch = BranchLocationService.findNearestBranch(
          latitude,
          longitude,
        );

        if (nearestBranch != null) {
          // Within office range - save branch name
          checkInData['checkInLocation'] = nearestBranch.branchName;
        } else {
          // Outside office range - save current address
          checkInData['checkInLocation'] = address ?? 'Unknown Location';
        }
      } else {
        // No GPS data - use fallback
        checkInData['checkInLocation'] = address ?? employeeData['locationName'] ?? 'Unknown Location';
      }

      await _attendanceService.checkInOut(checkInData);
    } catch (e) {
      throw Exception('Check-in failed: ${e.toString()}');
    }
  }

  Future<void> checkOut(
    String userId,
    Map<String, dynamic> employeeData, {
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final statusResponse = await _attendanceService.getTodayAttendanceStatus(
        employeeId: userId,
      );

      if (statusResponse['success'] != true) {
        throw Exception(
          'No check-in record found for today. Please check in first.',
        );
      }

      // Get the record from the status response
      final checkInRecord = statusResponse['record'];
      if (checkInRecord == null) {
        throw Exception('No open check-in record found for today.');
      }

      // Get Thailand local time (UTC+7)
      final thailandTime = _getThailandTime();
      final dateString = thailandTime['date']!;
      final localTimeString = thailandTime['time']!;
      final timestamp = thailandTime['timestamp']!;

      // Update the existing record with checkout information

      final checkOutData = {
        'id': checkInRecord['id'], // Use existing record ID
        'uid': checkInRecord['uid'], // Use existing UID
        'employeeId': checkInRecord['employeeId'], // Use existing employeeId
        'employeeName':
            checkInRecord['employeeName'], // Use existing employeeName
        'location': address ?? checkInRecord['location'], // Use new address if provided
        'branch': checkInRecord['branch'], // Use existing branch
        'branchName': checkInRecord['branchName'], // Use existing branchName
        'type': 'checkout', // Change type to checked_out
        'date': dateString, // Update date
        'time': localTimeString, // Update time
        'checkInAt': checkInRecord['checkInAt'], // Keep existing checkInAt
        'checkOutAt': localTimeString, // Add checkout time
        'timestamp': timestamp, // Update timestamp with Thailand time
        'createdAt': checkInRecord['createdAt'], // Keep existing createdAt
        'updatedAt': timestamp, // Update updatedAt with Thailand time
      };

      // Add GPS coordinates if provided for checkout
      if (latitude != null) {
        checkOutData['checkOutLatitude'] = latitude;
      }
      if (longitude != null) {
        checkOutData['checkOutLongitude'] = longitude;
      }
      if (address != null) {
        checkOutData['checkOutAddress'] = address;
      }

      // Determine checkOutLocation field for checkout based on branch proximity
      if (latitude != null && longitude != null) {
        // Check if user is within office range
        final nearestBranch = BranchLocationService.findNearestBranch(
          latitude,
          longitude,
        );

        if (nearestBranch != null) {
          // Within office range - save branch name
          checkOutData['checkOutLocation'] = nearestBranch.branchName;
        } else {
          // Outside office range - save current address
          checkOutData['checkOutLocation'] = address ?? 'Unknown Location';
        }
      } else {
        // No GPS data - use fallback
        checkOutData['checkOutLocation'] = address ?? checkInRecord['location'] ?? 'Unknown Location';
      }

      await _attendanceService.checkInOutWithRecordData(checkOutData);
    } catch (e) {
      throw Exception('Check-out failed: ${e.toString()}');
    }
  }

  Future<List<Attendance>> getAttendanceHistory(String userId) async {
    try {
      final response = await _attendanceService.getAttendanceHistory(userId);

      final attendanceList = response.map((json) {
        final attendance = Attendance.fromJson(json);

        return attendance;
      }).toList();

      return attendanceList;
    } catch (e) {
      return [];
    }
  }
}

// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return AttendanceRepository(attendanceService);
});

// Provider for attendance controller
final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AsyncValue<List<Attendance>>>((
      ref,
    ) {
      final repository = ref.watch(attendanceRepositoryProvider);
      final authService = ref.watch(authServiceProvider);
      return AttendanceController(repository, authService, ref);
    });

class AttendanceController extends StateNotifier<AsyncValue<List<Attendance>>> {
  final AttendanceRepository _repository;
  final AuthService _authService;
  final Ref _ref;
  String? _openId;

  AttendanceController(this._repository, this._authService, this._ref)
    : super(const AsyncValue.loading()) {
    load();
  }

  String? get openId => _openId;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();

      // Get real employee ID from auth service
      final employeeId = _authService.currentEmployeeId;

      if (employeeId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final attendance = await _repository.listMyAttendance(employeeId);
      state = AsyncValue.data(attendance);

      // Update openId based on attendance data
      _updateOpenId(attendance);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Silent reload - updates data without showing loading indicator
  Future<void> silentReload() async {
    try {
      // Don't set state to loading - keep existing data visible

      final employeeId = _authService.currentEmployeeId;

      if (employeeId == null) {
        return;
      }

      final attendance = await _repository.listMyAttendance(employeeId);
      state = AsyncValue.data(attendance);

      // Update openId based on attendance data
      _updateOpenId(attendance);
    } catch (e) {
      // Don't show error, just keep existing data
    }
  }

  Future<void> checkIn(
    Map<String, dynamic> employeeData, {
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        throw Exception('No employee ID found, user not logged in');
      }

      await _repository.checkIn(
        employeeId,
        employeeData,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      await silentReload(); // Silent reload - no loading indicator
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkOut(
    Map<String, dynamic> employeeData, {
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        throw Exception('No employee ID found, user not logged in');
      }

      await _repository.checkOut(
        employeeId,
        employeeData,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      await silentReload(); // Silent reload - no loading indicator
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadAttendanceHistory() async {
    try {
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        return;
      }

      await _repository.getAttendanceHistory(employeeId);
    } catch (e) {}
  }

  Future<void> loadAttendanceList() async {
    try {
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        return;
      }

      final list = await _repository.getAttendanceList(employeeId);
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> toggleCheck() async {
    try {
      // Get real employee data from auth service
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        throw Exception('No employee ID found, user not logged in');
      }

      // Get employee profile data
      final profileResponse = await _authService.getEmployeeProfile();
      if (profileResponse['success'] != true) {
        throw Exception(
          'Failed to get employee profile: ${profileResponse['message']}',
        );
      }

      final employeeProfile = profileResponse['employee'];
      final employeeData = {
        'fullName':
            '${employeeProfile['firstName'] ?? ''} ${employeeProfile['lastName'] ?? ''}'
                .trim(),
        'positionName': employeeProfile['positionName'] ?? '',
        'companyName': employeeProfile['companyName'] ?? '',
        'locationName': employeeProfile['locationName'] ?? '',
        'branchName': employeeProfile['branchName'] ?? '',
      };

      // Check current status using status API
      final attendanceService = _ref.read(attendanceServiceProvider);
      final statusResponse = await attendanceService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (statusResponse['success'] == true) {
        final status = statusResponse['status'];

        if (status == 'checked_in') {
          // User is checked in, so check out

          await checkOut(employeeData);
        } else if (status == 'checked_out') {
          // User is already checked out
          throw Exception('You have already checked out today');
        } else {
          // User is not checked in, so check in

          await checkIn(employeeData);
        }
      } else {
        // Status API failed, fall back to local data logic

        if (_openId == null) {
          // No open record, check in

          await checkIn(employeeData);
        } else {
          // Has open record, check out

          await checkOut(employeeData);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  void _updateOpenId(List<Attendance> attendance) {
    if (attendance.isNotEmpty) {
      final todayAttendance = attendance.first;
      if (todayAttendance.checkOutAt == null) {
        _openId = todayAttendance.id;
      } else {
        _openId = null;
      }
    } else {
      _openId = null;
    }
  }
}
