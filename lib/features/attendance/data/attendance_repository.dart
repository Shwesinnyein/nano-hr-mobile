import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/attendance_service.dart';
import 'attendance_model.dart';

class AttendanceRepository {
  final AttendanceService _attendanceService;

  AttendanceRepository(this._attendanceService);

  Future<List<Attendance>> listMyAttendance(String userId) async {
    try {
      print(
        '🔍 AttendanceRepository: Getting today\'s attendance for: $userId',
      );

      final response = await _attendanceService.getTodayAttendance(userId);

      print('🔍 AttendanceRepository: Today\'s attendance data: $response');

      final attendanceList = response.map((json) {
        print('🔍 AttendanceRepository: Processing today\'s item: $json');
        final attendance = Attendance.fromJson(json);
        print(
          '🔍 AttendanceRepository: Created attendance: ${attendance.id} - CheckIn: ${attendance.checkInAt} - CheckOut: ${attendance.checkOutAt}',
        );
        return attendance;
      }).toList();

      print(
        '🔍 AttendanceRepository: Final attendance list length: ${attendanceList.length}',
      );
      return attendanceList;
    } catch (e) {
      print('❌ AttendanceRepository: Error getting today\'s attendance: $e');
      return [];
    }
  }

  Future<void> checkIn(String userId, Map<String, dynamic> employeeData) async {
    try {
      print('🔍 AttendanceRepository: Checking in for user: $userId');

      final checkInData = {
        'employeeId': userId,
        'employeeName': employeeData['fullName'] ?? 'Unknown',
        'position': employeeData['positionName'] ?? 'Employee',
        'positionName': employeeData['positionName'] ?? 'Employee',
        'company': employeeData['companyName'] ?? 'NANO-STORES',
        'companyName': employeeData['companyName'] ?? 'NANO-STORES',
        'locationName': employeeData['locationName'] ?? 'Bangkok',
        'location': employeeData['locationName'] ?? 'Bangkok',
        'branch': employeeData['branchName'] ?? 'Office',
        'branchName': employeeData['branchName'] ?? 'Office',
        'type': 'checkin',
      };

      final response = await _attendanceService.checkInOut(checkInData);

      print(
        '✅ AttendanceRepository: Check-in successful: ${response['message']}',
      );
    } catch (e) {
      print('❌ AttendanceRepository: Check-in failed: $e');
      throw Exception('Check-in failed: ${e.toString()}');
    }
  }

  Future<void> checkOut(
    String userId,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      print('🔍 AttendanceRepository: Checking out for user: $userId');

      final checkOutData = {
        'employeeId': userId,
        'employeeName': employeeData['fullName'] ?? 'Unknown',
        'position': employeeData['positionName'] ?? 'Employee',
        'positionName': employeeData['positionName'] ?? 'Employee',
        'company': employeeData['companyName'] ?? 'NANO-STORES',
        'companyName': employeeData['companyName'] ?? 'NANO-STORES',
        'locationName': employeeData['locationName'] ?? 'Bangkok',
        'location': employeeData['locationName'] ?? 'Bangkok',
        'branch': employeeData['branchName'] ?? 'Office',
        'branchName': employeeData['branchName'] ?? 'Office',
        'type': 'checkout',
      };

      final response = await _attendanceService.checkInOut(checkOutData);

      print(
        '✅ AttendanceRepository: Check-out successful: ${response['message']}',
      );
    } catch (e) {
      print('❌ AttendanceRepository: Check-out failed: $e');
      throw Exception('Check-out failed: ${e.toString()}');
    }
  }

  Future<List<Attendance>> getAttendanceHistory(String userId) async {
    try {
      print('🔍 AttendanceRepository: Getting attendance history for: $userId');

      final response = await _attendanceService.getAttendanceHistory(userId);

      print('🔍 AttendanceRepository: Attendance history data: $response');

      final attendanceList = response.map((json) {
        print('🔍 AttendanceRepository: Processing history item: $json');
        final attendance = Attendance.fromJson(json);
        print(
          '🔍 AttendanceRepository: Created attendance: ${attendance.id} - CheckIn: ${attendance.checkInAt} - CheckOut: ${attendance.checkOutAt}',
        );
        return attendance;
      }).toList();

      print(
        '🔍 AttendanceRepository: Final history list length: ${attendanceList.length}',
      );
      return attendanceList;
    } catch (e) {
      print('❌ AttendanceRepository: Error getting attendance history: $e');
      return [];
    }
  }
}

// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final attendanceService = AttendanceService();
  return AttendanceRepository(attendanceService);
});

// Provider for attendance controller
final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AsyncValue<List<Attendance>>>((
      ref,
    ) {
      final repository = ref.watch(attendanceRepositoryProvider);
      return AttendanceController(repository);
    });

class AttendanceController extends StateNotifier<AsyncValue<List<Attendance>>> {
  final AttendanceRepository _repository;
  String? _openId;

  AttendanceController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  String? get openId => _openId;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final attendance = await _repository.listMyAttendance('emp001');
      state = AsyncValue.data(attendance);

      // Update openId based on attendance data
      _updateOpenId(attendance);

      print(
        '✅ AttendanceController: Loaded ${attendance.length} attendance records',
      );
    } catch (e) {
      print('❌ AttendanceController: Error loading attendance: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> checkIn(Map<String, dynamic> employeeData) async {
    try {
      await _repository.checkIn('emp001', employeeData);
      await load(); // Reload data after check-in
    } catch (e) {
      print('❌ AttendanceController: Check-in error: $e');
      rethrow;
    }
  }

  Future<void> checkOut(Map<String, dynamic> employeeData) async {
    try {
      await _repository.checkOut('emp001', employeeData);
      await load(); // Reload data after check-out
    } catch (e) {
      print('❌ AttendanceController: Check-out error: $e');
      rethrow;
    }
  }

  Future<void> loadAttendanceHistory() async {
    try {
      final history = await _repository.getAttendanceHistory('emp001');
      print('✅ AttendanceController: Loaded ${history.length} history records');
    } catch (e) {
      print('❌ AttendanceController: Error loading history: $e');
    }
  }

  Future<void> toggleCheck() async {
    try {
      // Mock employee data for check-in/out
      final employeeData = {
        'fullName': 'John Doe',
        'positionName': 'Software Developer',
        'companyName': 'NANO-STORES',
        'locationName': 'Bangkok',
        'branchName': 'Office',
      };

      if (_openId == null) {
        // No open record, check in
        print('🔄 AttendanceController: Checking in...');
        await checkIn(employeeData);
      } else {
        // Has open record, check out
        print('🔄 AttendanceController: Checking out...');
        await checkOut(employeeData);
      }
    } catch (e) {
      print('❌ AttendanceController: Toggle check error: $e');
      rethrow;
    }
  }

  void _updateOpenId(List<Attendance> attendance) {
    if (attendance.isNotEmpty) {
      final todayAttendance = attendance.first;
      if (todayAttendance.checkInAt != null &&
          todayAttendance.checkOutAt == null) {
        _openId = todayAttendance.id;
        print('🔍 AttendanceController: Open ID set to: $_openId');
      } else {
        _openId = null;
        print('🔍 AttendanceController: No open attendance record');
      }
    } else {
      _openId = null;
      print('🔍 AttendanceController: No attendance records');
    }
  }
}
