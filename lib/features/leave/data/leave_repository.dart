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
      final response = await _leaveService.createLeaveRequest(requestData);

      if (response['success'] == true) {
        final leaveRequest = LeaveRequest.fromJson(response['leaveRequest']);

        return leaveRequest;
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to submit leave request';

        throw Exception(errorMessage);
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

  // Cache for leave data
  static final Map<String, LeaveVm> _leaveDataCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  LeaveController(this._repository, this._employeeId)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();

      // Check cache first (valid for 2 minutes)
      final now = DateTime.now();
      if (_cacheTimestamps.containsKey(_employeeId) &&
          now.difference(_cacheTimestamps[_employeeId]!).inMinutes < 2 &&
          _leaveDataCache.containsKey(_employeeId)) {
        state = AsyncValue.data(_leaveDataCache[_employeeId]!);
        return;
      }

      final stopwatch = Stopwatch()..start();

      final results = await Future.wait([
        _repository.getLeaveBalance(_employeeId),
        _repository.getLeaveRequests(_employeeId),
      ]);

      stopwatch.stop();

      final balance = results[0] as LeaveBalance;
      final requests = results[1] as List<LeaveRequest>;
      final leaveVm = LeaveVm(balance, requests);

      // Cache the result
      _leaveDataCache[_employeeId] = leaveVm;
      _cacheTimestamps[_employeeId] = now;

      state = AsyncValue.data(leaveVm);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> submitRequest(Map<String, dynamic> requestData) async {
    try {
      await _repository.submitRequest(requestData);
      // Clear cache after submission to ensure fresh data
      _leaveDataCache.remove(_employeeId);
      _cacheTimestamps.remove(_employeeId);
      await load(); // Reload data after submission
    } catch (e) {
      rethrow;
    }
  }

  // Method to clear cache (call when data might be stale)
  static void clearCache(String employeeId) {
    _leaveDataCache.remove(employeeId);
    _cacheTimestamps.remove(employeeId);
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
