import 'mock_data_service.dart';

class AttendanceService {
  // Check in/out attendance
  Future<Map<String, dynamic>> checkInOut(Map<String, dynamic> data) async {
    try {
      print('🔄 AttendanceService: Checking in/out for employee: ${data['employeeId']}');
      
      final response = await MockDataService.checkInOut(data);
      
      print('✅ AttendanceService: Check in/out successful');
      return response;
    } catch (e) {
      print('❌ AttendanceService: Check in/out failed: $e');
      throw Exception('Check in/out failed: ${e.toString()}');
    }
  }

  // Get today's attendance
  Future<List<Map<String, dynamic>>> getTodayAttendance(String employeeId) async {
    try {
      print('🔄 AttendanceService: Getting today\'s attendance for: $employeeId');
      
      final attendance = await MockDataService.getTodayAttendance(employeeId);
      
      print('✅ AttendanceService: Today\'s attendance retrieved: ${attendance.length} records');
      return attendance;
    } catch (e) {
      print('❌ AttendanceService: Failed to get today\'s attendance: $e');
      throw Exception('Failed to get today\'s attendance: ${e.toString()}');
    }
  }

  // Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory(String employeeId) async {
    try {
      print('🔄 AttendanceService: Getting attendance history for: $employeeId');
      
      final history = await MockDataService.getAttendanceHistory(employeeId);
      
      print('✅ AttendanceService: Attendance history retrieved: ${history.length} records');
      return history;
    } catch (e) {
      print('❌ AttendanceService: Failed to get attendance history: $e');
      throw Exception('Failed to get attendance history: ${e.toString()}');
    }
  }
}