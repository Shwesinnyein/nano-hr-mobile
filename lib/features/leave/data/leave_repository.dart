import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/leave_service.dart';
import 'leave_model.dart';

class LeaveRepository {
  final LeaveService _leaveService;

  LeaveRepository(this._leaveService);

  Future<LeaveBalance> getLeaveBalance(String employeeId) async {
    try {
      final response = await _leaveService.getLeaveBalance(employeeId);

      if (response['success'] == true) {
        return LeaveBalance.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get leave balance');
      }
    } catch (e) {
      throw Exception('Failed to get leave balance: ${e.toString()}');
    }
  }

  Future<LeaveSettingsResponse> getLeaveSettings(String employeeId) async {
    try {
      final response = await _leaveService.getLeaveSettings(employeeId);
      return LeaveSettingsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get leave settings: ${e.toString()}');
    }
  }

  Future<List<LeaveRequest>> getLeaveRequests(String employeeId) async {
    try {
      final response = await _leaveService.getLeaveRequests(employeeId);

      return response.map((json) => LeaveRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get leave requests: ${e.toString()}');
    }
  }

  Future<LeaveRequest> submitRequest(Map<String, dynamic> requestData) async {
    try {
      print('📝 Leave Repository: Submitting request with data: $requestData');

      final response = await _leaveService.createLeaveRequest(requestData);
      print('📝 Leave Repository: Received response: $response');

      // Check if response is a Map
      if (response['success'] == true) {
        final leaveRequest = LeaveRequest.fromJson(response['leaveRequest']);
        print('✅ Leave Repository: Request submitted successfully');
        return leaveRequest;
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to submit leave request';
        print('❌ Leave Repository: API error: $errorMessage');
        throw Exception(errorMessage);
      }
        } catch (e) {
      print('❌ Leave Repository: Exception: ${e.toString()}');
      throw Exception('Failed to submit leave request: ${e.toString()}');
    }
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final leaveService = LeaveService();
  return LeaveRepository(leaveService);
});

class LeaveVm {
  LeaveVm(this.balance, this.requests);
  final LeaveBalance balance;
  final List<LeaveRequest> requests;
}

class LeaveController extends StateNotifier<AsyncValue<LeaveVm>> {
  final LeaveRepository _repository;
  final String _employeeId;

  LeaveController(this._repository, this._employeeId)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();

      final balance = await _repository.getLeaveBalance(_employeeId);
      final requests = await _repository.getLeaveRequests(_employeeId);

      state = AsyncValue.data(LeaveVm(balance, requests));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> submitRequest(Map<String, dynamic> requestData) async {
    try {
      await _repository.submitRequest(requestData);
      await load(); // Reload data after submission
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for LeaveController
final leaveControllerProvider =
    StateNotifierProvider.family<LeaveController, AsyncValue<LeaveVm>, String>((
      ref,
      employeeId,
    ) {
      final repository = ref.watch(leaveRepositoryProvider);
      return LeaveController(repository, employeeId);
    });

// Provider for leave requests list
final employeeLeaveListProvider =
    FutureProvider.family<List<LeaveRequest>, String>((ref, employeeId) async {
      final repository = ref.watch(leaveRepositoryProvider);
      return await repository.getLeaveRequests(employeeId);
    });

// Provider for leave settings
final leaveSettingsProvider =
    FutureProvider.family<LeaveSettingsResponse, String>((
      ref,
      employeeId,
    ) async {
      final repository = ref.watch(leaveRepositoryProvider);
      return await repository.getLeaveSettings(employeeId);
    });
