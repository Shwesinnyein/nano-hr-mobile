import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/leave_service.dart';
import 'leave_model.dart';

class LeaveRepository {
  final LeaveService _leaveService;

  LeaveRepository(this._leaveService);

  Future<LeaveBalance> getLeaveBalance() async {
    try {
      // Return mock leave balance
      return LeaveBalance(
        annualLeave: 12,
        sickLeave: 5,
        personalLeave: 3,
        usedAnnualLeave: 2,
        usedSickLeave: 1,
        usedPersonalLeave: 0,
      );
    } catch (e) {
      throw Exception('Failed to get leave balance: ${e.toString()}');
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

  Future<LeaveRequest> submitRequest(LeaveRequest request) async {
    try {
      final requestData = request.toJson();
      final response = await _leaveService.createLeaveRequest(requestData);

      if (response['success'] == true) {
        return LeaveRequest.fromJson(response['data']);
      } else {
        throw Exception(
          response['message'] ?? 'Failed to submit leave request',
        );
      }
    } catch (e) {
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

      final balance = await _repository.getLeaveBalance();
      final requests = await _repository.getLeaveRequests(_employeeId);

      state = AsyncValue.data(LeaveVm(balance, requests));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> submitRequest(LeaveRequest request) async {
    try {
      await _repository.submitRequest(request);
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
