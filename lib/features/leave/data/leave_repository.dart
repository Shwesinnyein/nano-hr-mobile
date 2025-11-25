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
        return LeaveBalance.fromJson(response);
      } else {
        // Extract clean error message
        final errorMessage = response['message']?.toString() ?? 'Failed to get leave balance';
        // Remove nested exception prefixes for cleaner error messages
        final cleanMessage = errorMessage
            .replaceAll(RegExp(r'Exception:\s*'), '')
            .replaceAll(RegExp(r'Failed to get leave balance:\s*'), '')
            .trim();
        throw Exception(cleanMessage.isEmpty ? 'Failed to get leave balance' : cleanMessage);
      }
    } catch (e) {
      // Don't double-wrap exceptions
      if (e is Exception) {
        rethrow;
      }
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
        // API returns 'data' field with leave request object
        final leaveRequestData = response['data'] ?? response['leaveRequest'];
        
        if (leaveRequestData is Map<String, dynamic>) {
          return LeaveRequest.fromJson(leaveRequestData);
        } else {
          throw Exception('Invalid leave request data format');
        }
      } else {
        // Error response includes messageTh, eligibleForAnnualLeave, monthsWithCompany, requiredMonths
        final isThai = false; // Could be passed as parameter if needed
        final errorMessage = isThai && response['messageTh'] != null
            ? response['messageTh'] as String
            : response['message'] as String? ?? 'Failed to submit leave request';

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
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

  
  static final Map<String, LeaveVm> _leaveDataCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  LeaveController(this._repository, this._employeeId)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();

      
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
      
      _leaveDataCache.remove(_employeeId);
      _cacheTimestamps.remove(_employeeId);
      await load(); 
    } catch (e) {
      rethrow;
    }
  }

  
  static void clearCache(String employeeId) {
    _leaveDataCache.remove(employeeId);
    _cacheTimestamps.remove(employeeId);
  }

  
  static void clearAllCache() {
    _leaveDataCache.clear();
    _cacheTimestamps.clear();
  }

            
  Future<void> forceRefresh() async {
    _leaveDataCache.remove(_employeeId);
    _cacheTimestamps.remove(_employeeId);
    await load();
  }
}

final leaveControllerProvider =
    StateNotifierProvider.family<LeaveController, AsyncValue<LeaveVm>, String>((
      ref,
      employeeId,
    ) {
      final repository = ref.watch(leaveRepositoryProvider);
      return LeaveController(repository, employeeId);
    });

final employeeLeaveListProvider =
    FutureProvider.family<List<LeaveRequest>, String>((ref, employeeId) async {
      final repository = ref.watch(leaveRepositoryProvider);
      return await repository.getLeaveRequests(employeeId);
    });

final leaveSettingsProvider =
    FutureProvider.family<LeaveSettingsResponse, String>((
      ref,
      employeeId,
    ) async {
      final repository = ref.watch(leaveRepositoryProvider);
      return await repository.getLeaveSettings(employeeId);
    });
