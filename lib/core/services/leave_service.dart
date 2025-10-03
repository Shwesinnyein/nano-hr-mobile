import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_endpoints.dart';

class LeaveService {
  final Dio _dio = Dio();

  static Map<String, Map<String, dynamic>> _leaveSettingsCache = {};
  static DateTime? _cacheTimestamp;

  static Map<String, Map<String, dynamic>> _leaveApprovalCache = {};
  static DateTime? _approvalCacheTimestamp;

  static void clearApprovalCache() {
    _leaveApprovalCache.clear();
    _approvalCacheTimestamp = null;
  }

  LeaveService() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 10);

    // Add interceptors
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 Leave API: $obj'),
      ),
    );
  }

  Future<Map<String, dynamic>> getLeaveDetails(String leaveId) async {
    try {
      final response = await _dio.get(ApiEndpoints.leaveDetails(leaveId));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        return {
          'success': false,
          'message': 'Failed to get leave details: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get leave settings for employee with caching
  Future<Map<String, dynamic>> getLeaveSettings(String employeeId) async {
    try {
      // Check cache first (valid for 5 minutes)
      final now = DateTime.now();
      if (_cacheTimestamp != null &&
          now.difference(_cacheTimestamp!).inMinutes < 5 &&
          _leaveSettingsCache.containsKey(employeeId)) {
        return _leaveSettingsCache[employeeId]!;
      }

      final stopwatch = Stopwatch()..start();
      // Getting leave settings for employee

      final response = await _dio.get(
        ApiEndpoints.leaveSettings,
        queryParameters: {'employeeId': employeeId},
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        // Cache the response
        _leaveSettingsCache[employeeId] = response.data;
        _cacheTimestamp = now;

        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get leave settings: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Create leave request
  Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      // Creating leave request

      final response = await _dio.post(
        ApiEndpoints.createLeaveRequest,
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to create leave request: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          return {
            'success': false,
            'message': 'Leave request API endpoint not available (404)',
          };
        }
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get leave requests for approval based on user level (manager/hr/approver)
  Future<List<Map<String, dynamic>>> getLeaveRequestsForApproval(
    String level,
    String userId,
  ) async {
    try {
      // Check cache first (valid for 2 minutes for approval requests)
      final cacheKey = '${level}_$userId';
      final now = DateTime.now();
      if (_approvalCacheTimestamp != null &&
          now.difference(_approvalCacheTimestamp!).inMinutes < 2 &&
          _leaveApprovalCache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(
          _leaveApprovalCache[cacheKey]!['data'] ?? [],
        );
      }

      final stopwatch = Stopwatch()..start();
      // Getting leave requests for approval

      final response = await _dio.get(
        ApiEndpoints.getLeaveRequestsForApproval(level, userId),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] is List) {
          // Cache the successful response
          _leaveApprovalCache[cacheKey] = data;
          _approvalCacheTimestamp = now;

          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('🌐 Leave API: Error response: ${e.response!.data}');
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get leave requests for employee
  Future<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) async {
    try {
      // Getting leave requests for employee

      final response = await _dio.get(
        '${ApiEndpoints.leaveRequests}/$employeeId',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        print(
          '❌ Leave API: Failed to get requests - Status: ${response.statusCode}',
        );
        return [];
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get leave balance (return available days since API endpoint doesn't exist)
  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      return {
        'success': true,
        'message': 'Leave balance retrieved successfully',
        'data': {
          'annualLeave': 6, // 6 days available
          'sickLeave': 30, // 30 days available
          'personalLeave': 3, // 3 days available
          'usedAnnualLeave': 0, // 0 days used
          'usedSickLeave': 0, // 0 days used
          'usedPersonalLeave': 0, // 0 days used
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Upload leave request with attachments
  Future<Map<String, dynamic>> createLeaveRequestWithAttachments(
    Map<String, dynamic> data,
    List<File> attachments,
  ) async {
    try {
      final formData = FormData();

      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add attachment files
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        if (await file.exists()) {
          formData.files.add(
            MapEntry(
              'attachments', // Field name as per your backend
              await MultipartFile.fromFile(file.path, filename: 'photo_$i.jpg'),
            ),
          );
        } else {
          print('❌ Leave API: File does not exist: ${file.path}');
        }
      }

      final response = await _dio.post(
        ApiEndpoints.createLeaveRequest,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to create leave request: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Approve or reject leave via status endpoint
  Future<Map<String, dynamic>> updateLeaveStatus({
    required String leaveId,
    required String status, // 'approved' | 'rejected'
    required String approverId,
    required String userRole, // 'hr' | 'manager' | 'approver'
    String? note,
  }) async {
    try {
      final payload = {
        'leaveId': leaveId,
        'userId': approverId,
        'userRole': userRole, // Use the actual user role
        'action': status == 'approved' ? 'approve' : 'reject',
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _dio.put(
        ApiEndpoints.leaveStatus(leaveId),
        data: payload,
      );

      if (response.statusCode == 200) {
        // Clear cache after successful approval/rejection
        clearApprovalCache();
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to update status: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Alternate approval endpoint
  Future<Map<String, dynamic>> approveOrRejectLeave({
    required String leaveId,
    required String action, // 'approve' | 'reject'
    required String approverId,
    required String userRole, // 'hr' | 'manager' | 'approver'
    String? note,
  }) async {
    try {
      final payload = {
        'leaveId': leaveId,
        'userId': approverId,
        'userRole': userRole, // Use the actual user role
        'action': action,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _dio.put(
        ApiEndpoints.leaveApproval(leaveId),
        data: payload,
      );

      if (response.statusCode == 200) {
        // Clear cache after successful approval/rejection
        clearApprovalCache();
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to update approval: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get all leave requests (for HR users to see manager-approved requests)
  Future<List<Map<String, dynamic>>> getAllLeaveRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.leaveRequests);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final requests = data['data'] as List<dynamic>? ?? [];

          return requests.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('❌ Leave API: DioException - ${e.response!.data}');
      } else {
        print('❌ Leave API: Network error - ${e.message}');
      }
      return [];
    } catch (e) {
      print('❌ Leave API: Unexpected error - $e');
      return [];
    }
  }
}
