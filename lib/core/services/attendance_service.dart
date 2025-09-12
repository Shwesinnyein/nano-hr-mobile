import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService _apiService;

  AttendanceService(this._apiService);

  Future<List<Map<String, dynamic>>> getAttendanceList(
    String employeeId,
  ) async {
    try {
      final response = await _apiService.getAttendanceList(
        employeeId: employeeId,
      );
      print("response ssn3 $response");
      if (response['success'] == true) {
        // Handle nested data structure
        final outerData = response['data'] as Map<String, dynamic>;
        if (outerData['success'] == true) {
          final data = outerData['data'] as List<dynamic>;
          final result = data.cast<Map<String, dynamic>>();
          print("response ssn4 parsed data: $result");
          return result;
        } else {
          throw Exception(
            outerData['message'] ?? 'Failed to get attendance history',
          );
        }
      } else {
        throw Exception(
          response['message'] ?? 'Failed to get attendance history',
        );
      }
    } catch (e) {
      throw Exception('Failed to get attendance history: ${e.toString()}');
    }
  }

  // Check in/out attendance
  Future<Map<String, dynamic>> checkInOut(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.checkInOut(
        employeeId: data['employeeId'],
        employeeName: data['employeeName'],
        position: data['position'],
        positionName: data['positionName'],
        company: data['company'],
        companyName: data['companyName'],
        locationName: data['locationName'],
        location: data['location'],
        branch: data['branch'],
        branchName: data['branchName'],
        type: data['type'],
      );

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Check in/out failed');
      }
    } catch (e) {
      throw Exception('Check in/out failed: ${e.toString()}');
    }
  }

  // Get today's attendance
  Future<List<Map<String, dynamic>>> getTodayAttendance(
    String employeeId,
  ) async {
    try {
      final response = await _apiService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        final record = response['record'];
        if (record != null) {
          final result = [record as Map<String, dynamic>];

          return result;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get today\'s attendance: ${e.toString()}');
    }
  }

  // Get today's attendance status
  Future<Map<String, dynamic>> getTodayAttendanceStatus({
    required String employeeId,
  }) async {
    try {
      final response = await _apiService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to get today attendance status: ${e.toString()}');
    }
  }

  // Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String employeeId,
  ) async {
    try {
      final response = await _apiService.getAttendanceHistory(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        final result = data.cast<Map<String, dynamic>>();

        return result;
      } else {
        throw Exception(
          response['message'] ?? 'Failed to get attendance history',
        );
      }
    } catch (e) {
      throw Exception('Failed to get attendance history: ${e.toString()}');
    }
  }

  // Check in/out with full record data (for updating existing records)
  Future<Map<String, dynamic>> checkInOutWithRecordData(
    Map<String, dynamic> recordData,
  ) async {
    try {
      final response = await _apiService.checkInOutWithRecordData(recordData);

      return response;
    } catch (e) {
      throw Exception('Check in/out with record data failed: ${e.toString()}');
    }
  }
}

// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AttendanceService(apiService);
});
