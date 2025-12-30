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
      'date': currentDate.toIso8601String().split('T')[0],
      'time': currentDate
          .toIso8601String()
          .split('T')[1]
          .split('.')[0], 
      'timestamp': currentDate.toIso8601String(), 
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

      if (latitude != null) {
        checkInData['latitude'] = latitude;
      }
      if (longitude != null) {
        checkInData['longitude'] = longitude;
      }
      if (address != null) {
        checkInData['address'] = address;
      }

      if (latitude != null && longitude != null) {
        final nearestBranch = BranchLocationService.findNearestBranch(
          latitude,
          longitude,
        );

        if (nearestBranch != null) {
          checkInData['checkInLocation'] = nearestBranch.branchName;
        } else {
          checkInData['checkInLocation'] = address ?? 'Unknown Location';
        }
      } else {
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
      // First check today's attendance
      final statusResponse = await _attendanceService.getTodayAttendanceStatus(
        employeeId: userId,
      );

      Map<String, dynamic>? checkInRecord;
      bool todayHasOpenRecord = false;
      
      if (statusResponse['success'] == true) {
        checkInRecord = statusResponse['record'];
        // Check if today's record is actually open (has check-in but no check-out)
        if (checkInRecord != null && 
            checkInRecord['checkInAt'] != null && 
            (checkInRecord['checkOutAt'] == null || checkInRecord['checkOutAt'] == '')) {
          todayHasOpenRecord = true;
        }
      }

      // If no open record today, check yesterday for night shifts (e.g., 22:00 - 06:00)
      // Only for Driver and Security positions
      final positionName = (employeeData['positionName'] ?? '').toString().toLowerCase();
      final isNightShiftPosition = positionName.contains('driver') || positionName.contains('security');
      
      // For night shift workers: if today doesn't have an open record, check yesterday
      if (isNightShiftPosition && !todayHasOpenRecord) {
        // Use Thailand timezone for calculating yesterday's date
        final thailandNow = DateTime.now().toUtc().add(const Duration(hours: 7));
        final yesterday = thailandNow.subtract(const Duration(days: 1));
        final yesterdayDateString =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        
        final yesterdayShiftData = await _attendanceService.getShiftDataWithFilter(
          employeeId: userId,
          date: yesterdayDateString,
        );
        
        if (yesterdayShiftData['success'] == true) {
          final yesterdayAttendanceData = yesterdayShiftData['attendanceData'] as List?;
          if (yesterdayAttendanceData?.isNotEmpty == true) {
            // Check all records from yesterday, not just the first one
            for (final yesterdayRecord in yesterdayAttendanceData!) {
              // If yesterday has check-in but no check-out, use that record
              if (yesterdayRecord['checkInAt'] != null && 
                  (yesterdayRecord['checkOutAt'] == null || yesterdayRecord['checkOutAt'] == '')) {
                checkInRecord = yesterdayRecord;
                break; // Use the first open record found
              }
            }
          }
        }
      }

      // Use the simpler checkout API format - backend will find the open record automatically
      // For overnight workers, backend handles "checked_in_previous_day" status
      String checkOutLocation = address ?? employeeData['locationName'] ?? 'Unknown Location';
      
      if (latitude != null && longitude != null) {
        final nearestBranch = BranchLocationService.findNearestBranch(
          latitude,
          longitude,
        );
        if (nearestBranch != null) {
          checkOutLocation = nearestBranch.branchName;
        }
      }

      // Build checkout payload according to API spec
      // Include all required fields for the checkInOut method
      final checkOutData = {
        'employeeId': userId,
        'employeeName': employeeData['fullName'] ?? 'Unknown',
        'position': employeeData['positionName'] ?? 'Employee',
        'positionName': employeeData['positionName'] ?? 'Employee',
        'company': employeeData['companyName'] ?? 'NANO-STORES',
        'companyName': employeeData['companyName'] ?? 'NANO-STORES',
        'locationName': address ?? employeeData['locationName'] ?? 'BKK',
        'location': address ?? employeeData['locationName'] ?? 'BKK',
        'branch': employeeData['branchName'] ?? '001',
        'branchName': employeeData['branchName'] ?? 'Main Branch',
        'type': 'checkout',
        'checkOutLocation': checkOutLocation, // Use checkOutLocation for checkout
      };

      // Add location coordinates if available
      if (latitude != null) {
        checkOutData['latitude'] = latitude;
      }
      if (longitude != null) {
        checkOutData['longitude'] = longitude;
      }
      if (address != null) {
        checkOutData['address'] = address;
      }

      // Use the simpler checkInOut method - backend will automatically find and update the open check-in record
      // Backend handles finding yesterday's record for overnight workers via "checked_in_previous_day" status
      // The checkInOut method throws an exception if it fails, so we don't need to check response
      await _attendanceService.checkInOut(checkOutData);
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

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final attendanceService = ref.watch(attendanceServiceProvider);
  return AttendanceRepository(attendanceService);
});

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

      final employeeId = _authService.currentEmployeeId;

      if (employeeId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final attendance = await _repository.listMyAttendance(employeeId);
      state = AsyncValue.data(attendance);

      _updateOpenId(attendance);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> silentReload() async {
    try {

      final employeeId = _authService.currentEmployeeId;

      if (employeeId == null) {
        return;
      }

      final attendance = await _repository.listMyAttendance(employeeId);
      state = AsyncValue.data(attendance);

      _updateOpenId(attendance);
    } catch (e) {
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
      await silentReload(); 
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
      await silentReload(); 
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
      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null) {
        throw Exception('No employee ID found, user not logged in');
      }

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

      final attendanceService = _ref.read(attendanceServiceProvider);
      final statusResponse = await attendanceService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (statusResponse['success'] == true) {
        final status = statusResponse['status'];

        if (status == 'checked_in') {
          await checkOut(employeeData);
        } else if (status == 'checked_out') {
          throw Exception('You have already checked out today');
        } else {
          await checkIn(employeeData);
        }
      } else {
        if (_openId == null) {
          await checkIn(employeeData);
        } else {
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
