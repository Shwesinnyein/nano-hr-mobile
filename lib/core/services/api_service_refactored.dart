import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';
import '../api/api_endpoints.dart';

/// Refactored API service with improved error handling and logging
class ApiServiceRefactored {
  late final Dio _dio;

  ApiServiceRefactored() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint('🌐 API: $object'),
      ));
    }

    // Add error handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final errorMessage = ErrorHandler.handleDioError(error);
        debugPrint('❌ API Error: $errorMessage');
        handler.next(error);
      },
    ));
  }

  /// Generic GET request with error handling
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw Exception(ErrorHandler.handleException(e));
    }
  }

  /// Generic POST request with error handling
  Future<Map<String, dynamic>> _post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw Exception(ErrorHandler.handleException(e));
    }
  }

  /// Handle API response and extract data
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      final data = response.data;
      
      // Handle different response formats
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is List) {
        return {
          'success': true,
          'data': data,
          'message': 'Request successful',
        };
      } else {
        return {
          'success': true,
          'data': data,
          'message': 'Request successful',
        };
      }
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  // Authentication endpoints

  /// Login user with email and password
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return await _post(
      ApiEndpoints.loginUser,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  /// Register user with email and password
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    return await _post(
      ApiEndpoints.registerUser,
      data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  // Employee endpoints

  /// Get employee profile by ID
  Future<Map<String, dynamic>> getEmployeeProfile({
    required String employeeId,
  }) async {
    return await _get('${ApiEndpoints.employeeProfile}/$employeeId');
  }

  /// Update employee profile
  Future<Map<String, dynamic>> updateProfile({
    required String employeeId,
    required Map<String, dynamic> data,
  }) async {
    return await _post(
      '${ApiEndpoints.updateProfile}/$employeeId',
      data: data,
    );
  }

  // Attendance endpoints

  /// Check in/out attendance
  Future<Map<String, dynamic>> checkInOut({
    required Map<String, dynamic> data,
  }) async {
    return await _post(
      ApiEndpoints.checkInOut,
      data: data,
    );
  }

  /// Get today's attendance status
  Future<Map<String, dynamic>> getTodayAttendanceStatus({
    required String employeeId,
  }) async {
    return await _get('${ApiEndpoints.attendanceStatus}/$employeeId');
  }

  /// Get attendance list for employee
  Future<Map<String, dynamic>> getAttendanceList({
    required String employeeId,
  }) async {
    return await _get('${ApiEndpoints.attendanceList}/$employeeId');
  }

  /// Get attendance history
  Future<Map<String, dynamic>> getAttendanceHistory({
    required String employeeId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    
    return await _get(
      '${ApiEndpoints.attendanceHistory}/$employeeId',
      queryParameters: queryParams,
    );
  }

  // Leave endpoints

  /// Create leave request
  Future<Map<String, dynamic>> createLeaveRequest({
    required Map<String, dynamic> data,
  }) async {
    return await _post(
      ApiEndpoints.createLeaveRequest,
      data: data,
    );
  }

  /// Get leave requests
  Future<Map<String, dynamic>> getLeaveRequests({
    required String employeeId,
  }) async {
    return await _get('${ApiEndpoints.leaveRequests}/$employeeId');
  }

  /// Get leave balance
  Future<Map<String, dynamic>> getLeaveBalance({
    required String employeeId,
  }) async {
    return await _get('${ApiEndpoints.leaveBalance}/$employeeId');
  }

  // File upload endpoints

  /// Upload file
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? folder,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (folder != null) 'folder': folder,
      });

      final response = await _dio.post(
        ApiEndpoints.uploadFile,
        data: formData,
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleDioError(e));
    } catch (e) {
      throw Exception(ErrorHandler.handleException(e));
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
