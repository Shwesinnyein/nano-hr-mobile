import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../features/leave/data/leave_repository.dart';
import 'auth_service.dart';

class LeaveService {
  final ApiClient _apiClient;

  LeaveService(this._apiClient);

  // Get leave balance
  Future<LeaveBalance> getLeaveBalance() async {
    // TODO: Implement when backend API is ready
    // For now, return sample data directly to avoid loading delays
    print('🔄 LeaveService: Using sample leave balance data');
    return LeaveBalance(
      vacationLeave:
          6.0, // ลาพักร้อน (Annual Leave) - 6 days, 0 hours remaining
      sickLeave:
          20.0, // ลาป่วย(ได้รับค่าจ้าง) (Paid Sick Leave) - 20 days, 6.30 hours remaining
      leaveWithoutPay:
          30.0, // ลา(โดยไม่ได้รับค่าจ้าง) (Unpaid Leave) - 30 days, 0 hours remaining
      maternityLeave:
          98.0, // ลาคลอด (Maternity Leave) - 98 days, 0 hours remaining
      leaveOfAbsencePaid:
          3.0, // ลากิจ(ได้รับค่าจ้าง) (Paid Personal Leave) - 0 days, 3 hours remaining
      emergency:
          3.0, // ลา(เพื่อจัดงานฌาปนกิจ) (Funeral Leave) - 3 days, 0 hours remaining
      study: 5.0,
      compensatory: 10.0,
    );
  }

  // Get leave requests
  Future<List<LeaveRequest>> getLeaveRequests({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    // TODO: Implement when backend API is ready
    // For now, return sample data directly to avoid loading delays
    print('🔄 LeaveService: Using sample leave requests data');
    return _getSampleLeaveRequests();
  }

  // Get employee leave list by EmployeeId
  Future<List<LeaveRequest>> getEmployeeLeaveList(String employeeId) async {
    try {
      print(
        '🔄 LeaveService: Fetching employee leave list for EmployeeId: $employeeId',
      );
      final response = await _apiClient.get(
        ApiEndpoints.getEmployeeLeaveList(employeeId),
      );
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> leaveDataList =
            responseData['data'] as List<dynamic>;

        print('🔍 LeaveService: Raw API data: $leaveDataList');

        final leaveRequests = leaveDataList.map((json) {
          print('🔍 LeaveService: Parsing leave request: $json');
          return LeaveRequest.fromJson(json as Map<String, dynamic>);
        }).toList();

        print(
          '✅ LeaveService: Successfully fetched ${leaveRequests.length} leave requests',
        );
        return leaveRequests;
      } else {
        print(
          '⚠️ LeaveService: No leave data found for EmployeeId: $employeeId',
        );
        return [];
      }
    } catch (e) {
      print('❌ LeaveService: Error fetching employee leave list: $e');
      // Fallback to sample data if API fails
      return _getSampleLeaveRequests();
    }
  }

  // Submit leave request
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.submitLeaveRequest,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return LeaveRequest.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to submit leave request: ${e.toString()}');
    }
  }

  // Create leave request with enhanced API
  Future<LeaveRequest> createLeaveRequest({
    required String employeeId,
    required String leaveType,
    required String leaveTypeName,
    required String requestType, // 'daily' or 'hourly'
    required String reason,
    String? attachment,
    // Daily leave fields
    String? fromDate,
    String? toDate,
    // Hourly leave fields
    String? date,
    String? workingShift,
    String? startTime,
    String? endTime,
  }) async {
    try {
      print(
        '🔄 LeaveService: Creating leave request for EmployeeId: $employeeId, Type: $requestType',
      );

      final requestData = {
        'employeeId': employeeId,
        'leaveType': leaveType,
        'leaveTypeName': leaveTypeName,
        'requestType': requestType,
        'reason': reason,
        'attachment': attachment,
      };

      // Add daily leave specific fields
      if (requestType == 'daily') {
        requestData['fromDate'] = fromDate;
        requestData['toDate'] = toDate;
      }

      // Add hourly leave specific fields
      if (requestType == 'hourly') {
        requestData['date'] = date;
        requestData['workingShift'] = workingShift;
        requestData['startTime'] = startTime;
        requestData['endTime'] = endTime;
      }

      final response = await _apiClient.post(
        ApiEndpoints.createLeaveRequest,
        data: requestData,
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true &&
          responseData['leaveRequest'] != null) {
        final leaveRequestData =
            responseData['leaveRequest'] as Map<String, dynamic>;
        final leaveRequest = LeaveRequest.fromJson(leaveRequestData);

        print('✅ LeaveService: Successfully created leave request');
        return leaveRequest;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to create leave request',
        );
      }
    } catch (e) {
      print('❌ LeaveService: Error creating leave request: $e');
      throw Exception('Failed to create leave request: ${e.toString()}');
    }
  }

  // Update leave request
  Future<LeaveRequest> updateLeaveRequest(
    String id,
    LeaveRequest request,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.getLeaveRequestById(id),
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return LeaveRequest.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to update leave request: ${e.toString()}');
    }
  }

  // Cancel leave request
  Future<void> cancelLeaveRequest(String id) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.getLeaveRequestById(id),
      );

      final apiResponse = ApiResponse.fromJson(response.data, (data) => data);

      if (!apiResponse.success) {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to cancel leave request: ${e.toString()}');
    }
  }

  // Get leave types
  Future<List<LeaveTypeData>> getLeaveTypes() async {
    // TODO: Implement when backend API is ready
    // For now, return sample data directly to avoid loading delays
    print('🔄 LeaveService: Using sample leave types data');
    return _getDefaultLeaveTypes();
  }

  // Sample data fallback
  List<LeaveRequest> _getSampleLeaveRequests() {
    return [
      LeaveRequest(
        id: '1',
        leaveType: 'annual',
        fromDate: DateTime.now().subtract(const Duration(days: 5)),
        toDate: DateTime.now().subtract(const Duration(days: 3)),
        reason: 'Family vacation',
        status: 'approved',
        submittedAt: DateTime.now().subtract(const Duration(days: 7)),
        approvedBy: 'HR Manager',
        approvedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      LeaveRequest(
        id: '2',
        leaveType: 'sick',
        fromDate: DateTime.now().subtract(const Duration(days: 2)),
        toDate: DateTime.now().subtract(const Duration(days: 2)),
        reason: 'Fever and cold',
        status: 'pending',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LeaveRequest(
        id: '3',
        leaveType: 'casual',
        fromDate: DateTime.now().add(const Duration(days: 1)),
        toDate: DateTime.now().add(const Duration(days: 1)),
        reason: 'Personal work',
        status: 'rejected',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        rejectedBy: 'HR Manager',
        rejectedAt: DateTime.now(),
        rejectionReason: 'Insufficient balance',
      ),
    ];
  }

  List<LeaveTypeData> _getDefaultLeaveTypes() {
    return [
      LeaveTypeData(
        type: 'annual',
        name: 'Annual Leave',
        icon: '🏖️',
        quota: 20,
        remaining: 18,
        color: 0xFF4CAF50,
      ),
      LeaveTypeData(
        type: 'sick',
        name: 'Sick Leave',
        icon: '🤒',
        quota: 10,
        remaining: 9,
        color: 0xFFF44336,
      ),
      LeaveTypeData(
        type: 'casual',
        name: 'Casual Leave',
        icon: '😊',
        quota: 5,
        remaining: 4,
        color: 0xFF2196F3,
      ),
      LeaveTypeData(
        type: 'maternity',
        name: 'Maternity Leave',
        icon: '👶',
        quota: 90,
        remaining: 90,
        color: 0xFFE91E63,
      ),
      LeaveTypeData(
        type: 'paternity',
        name: 'Paternity Leave',
        icon: '👨‍👶',
        quota: 15,
        remaining: 15,
        color: 0xFF9C27B0,
      ),
      LeaveTypeData(
        type: 'emergency',
        name: 'Emergency Leave',
        icon: '🚨',
        quota: 3,
        remaining: 3,
        color: 0xFFFF9800,
      ),
      LeaveTypeData(
        type: 'study',
        name: 'Study Leave',
        icon: '📚',
        quota: 5,
        remaining: 5,
        color: 0xFF607D8B,
      ),
      LeaveTypeData(
        type: 'compensatory',
        name: 'Compensatory Leave',
        icon: '⏰',
        quota: 10,
        remaining: 10,
        color: 0xFF795548,
      ),
    ];
  }
}

// Provider for LeaveService
final leaveServiceProvider = Provider<LeaveService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LeaveService(apiClient);
});

// Provider for employee leave list by EmployeeId
final employeeLeaveListProvider =
    FutureProvider.family<List<LeaveRequest>, String>((ref, employeeId) async {
      final leaveService = ref.watch(leaveServiceProvider);
      return leaveService.getEmployeeLeaveList(employeeId);
    });
