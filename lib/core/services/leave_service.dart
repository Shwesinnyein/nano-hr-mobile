import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

    // LogInterceptor removed - no logging in production
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

  Future<Map<String, dynamic>> getLeaveSettings(String employeeId) async {
    try {
      final now = DateTime.now();
      if (_cacheTimestamp != null &&
          now.difference(_cacheTimestamp!).inMinutes < 5 &&
          _leaveSettingsCache.containsKey(employeeId)) {
        return _leaveSettingsCache[employeeId]!;
      }

      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        ApiEndpoints.leaveSettings,
        queryParameters: {'employeeId': employeeId},
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
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

  Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createLeaveRequest,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Ensure response.data is a Map
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          return {'success': false, 'message': response.data as String};
        } else {
          return {'success': false, 'message': 'Invalid response format'};
        }
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
        // Ensure error response is a Map
        if (e.response!.data is Map<String, dynamic>) {
          return e.response!.data as Map<String, dynamic>;
        } else if (e.response!.data is String) {
          return {'success': false, 'message': e.response!.data as String};
        } else {
          return {'success': false, 'message': 'Invalid error response format'};
        }
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequestsForApproval(
    String level,
    String userId,
  ) async {
    try {
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

      final response = await _dio.get(
        ApiEndpoints.getLeaveRequestsForApproval(level, userId),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] is List) {
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
        // Error response handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.leaveRequests}/$employeeId',
      );

      if (response.statusCode == 200) {
        // Ensure response.data is a Map
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          
          if (data['success'] == true && data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else {
            return [];
          }
        } else if (response.data is List) {
          // Handle case where API directly returns a list
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Error response handled silently
      } else {
        // Network error handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/leave/balance/$employeeId',
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        // Ensure response.data is a Map, not a String
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          // If API returns a string, try to parse it as JSON
          try {
            return {'success': false, 'message': response.data as String};
          } catch (e) {
            return {'success': false, 'message': 'Invalid response format'};
          }
        } else {
          return {'success': false, 'message': 'Invalid response type'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to get leave balance: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Ensure response.data is a Map
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          // Extract error message from various possible fields
          final errorMessage = errorData['message'] ?? 
                              errorData['error'] ?? 
                              errorData['errorMessage'] ??
                              'A server error has occurred';
          return {
            'success': false,
            'message': errorMessage.toString(),
            ...errorData, // Include all error fields
          };
        } else if (e.response!.data is String) {
          return {'success': false, 'message': e.response!.data as String};
        } else {
          return {'success': false, 'message': 'Invalid error response format'};
        }
      } else {
        // Network error or connection issue
        return {
          'success': false,
          'message': e.message?.isNotEmpty == true 
              ? 'Network error: ${e.message}'
              : 'Unable to connect to server. Please check your internet connection.',
        };
      }
    } catch (e) {
      // Handle any other unexpected errors
      final errorMessage = e.toString();
      // Check if it's a serverless function error
      if (errorMessage.contains('FUNCTION_INVOCATION_FAILED') || 
          errorMessage.contains('sin1::')) {
        return {
          'success': false,
          'message': 'A server error has occurred. Please try again later.',
        };
      }
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

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

      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        if (await file.exists()) {
          final filename = 'photo_$i.jpg';
          formData.files.add(
            MapEntry(
              'attachments', 
              await MultipartFile.fromFile(file.path, filename: filename),
            ),
          );
        }
      }

      final response = await _dio.post(
        ApiEndpoints.createLeaveRequest,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Ensure response.data is a Map
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          return {'success': false, 'message': response.data as String};
        } else {
          return {'success': false, 'message': 'Invalid response format'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to create leave request: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Ensure error response is a Map
        if (e.response!.data is Map<String, dynamic>) {
          return e.response!.data as Map<String, dynamic>;
        } else if (e.response!.data is String) {
          return {'success': false, 'message': e.response!.data as String};
        } else {
          return {'success': false, 'message': 'Invalid error response format'};
        }
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateLeaveStatus({
    required String leaveId,
    required String status, 
    required String approverId,
    required String userRole, 
    String? note,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final payload = {
        'leaveId': leaveId,
        'userId': approverId,
        'userRole': userRole, 
        'action': status == 'approved' ? 'approve' : 'reject',
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _dio.put(
        ApiEndpoints.leaveStatus(leaveId),
        data: payload,
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
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

  Future<Map<String, dynamic>> approveOrRejectLeave({
    required String leaveId,
    required String action, 
    required String approverId,
    required String userRole, 
    String? note,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final payload = {
        'leaveId': leaveId,
        'userId': approverId,
        'userRole': userRole, 
        'action': action,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _dio.put(
        ApiEndpoints.leaveApproval(leaveId),
        data: payload,
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
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
        // Error response handled silently
      } else {
        // Network error handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllLeaveRequestsForApproval(
    String level,
    String userId,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      final pendingRequests = await getLeaveRequestsForApproval(level, userId);

      stopwatch.stop();

      return pendingRequests;
    } on DioException catch (e) {
      if (e.response != null) {
        // Error response handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllEmployeeLeaves() async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get('${ApiEndpoints.baseUrl}/leave/all');

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        // Error response handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeLeavesByBranch(
    String branchName,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/leave/branch/${Uri.encodeComponent(branchName)}',
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        // Error response handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeLeavesByTeam() async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get('${ApiEndpoints.baseUrl}/leave/team');

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        // Error response handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveHistory(String userId) async {
    try {
      final stopwatch = Stopwatch()..start();

      final url =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.getLeaveHistory(userId)}';

      final response = await _dio.get(url);

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true && data['data'] is List) {
          final leaves = List<Map<String, dynamic>>.from(data['data']);

          return leaves;
        }
      }

      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        // Error status handled silently
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
