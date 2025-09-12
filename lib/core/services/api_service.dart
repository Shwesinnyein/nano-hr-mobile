import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_endpoints.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add minimal logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) {
          // Only log errors and important info
          if (obj.toString().contains('Error') ||
              obj.toString().contains('Exception')) {
            print('🌐 API: $obj');
          }
        },
      ),
    );
  }

  // Register user
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerUser,
        data: {
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Registration failed',
          'error': e.response?.data,
        };
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loginUser,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        // Return the API response directly
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Return the API error response directly
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get employee profile
  Future<Map<String, dynamic>> getEmployeeProfile({
    required String employeeId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.employeeProfile}/$employeeId',
      );

      if (response.statusCode == 200) {
        // Return the API response directly
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get employee profile: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Return the API error response directly
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get employee list
  Future<Map<String, dynamic>> getEmployeeList({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final response = await _dio.get(
        ApiEndpoints.employeeList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Return the API response directly since it already has the expected structure
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get employee list: ${response.statusCode}',
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

  // Get today's attendance status
  Future<Map<String, dynamic>> getTodayAttendanceStatus({
    required String employeeId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.attendanceStatus}/$employeeId',
      );

      if (response.statusCode == 200) {
        // Return the API response directly
        return response.data;
      } else {
        return {
          'success': false,
          'message':
              'Failed to get today attendance status: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Return the API error response directly
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get attendance history
  Future<Map<String, dynamic>> getAttendanceHistory({
    required String employeeId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.attendanceHistory,
        queryParameters: {'employeeId': employeeId},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Attendance history retrieved',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get attendance history: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to get attendance history',
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get attendance list
  Future<Map<String, dynamic>> getAttendanceList({
    required String employeeId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.attendanceList}/$employeeId',
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Attendance list retrieved',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get attendance list: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get attendance list: ${e.toString()}',
      };
    }
  }

  // Check in/out
  Future<Map<String, dynamic>> checkInOut({
    required String employeeId,
    required String employeeName,
    required String position,
    required String positionName,
    required String company,
    required String companyName,
    required String locationName,
    required String location,
    required String branch,
    required String branchName,
    required String type, // 'checkin' or 'checkout'
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkInOut,
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'position': position,
          'positionName': positionName,
          'company': company,
          'companyName': companyName,
          'locationName': locationName,
          'location': location,
          'branch': branch,
          'branchName': branchName,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Check in/out successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Check in/out failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Check in/out failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Check in/out with full record data (for updating existing records)
  Future<Map<String, dynamic>> checkInOutWithRecordData(
    Map<String, dynamic> recordData,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkInOut,
        data: recordData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Check in/out successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Check in/out failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Check in/out failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
