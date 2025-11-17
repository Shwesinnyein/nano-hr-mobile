import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../api/api_endpoints.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('user_token');

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              if (kDebugMode) {
                print('⚠️ No JWT token found for request: ${options.path}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error getting token: $e');
            }
            // Ignore token errors, continue without auth
          }
          handler.next(options);
        },
      ),
    );

    // Add token expiration handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Handle 401 Unauthorized (token expired)
          if (error.response?.statusCode == 401) {
            try {
              // Clear stored login data
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('logged_in', false);
              await prefs.remove('user_token');
              await prefs.remove('user_id');
              await prefs.remove('employee_id');
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error clearing expired token: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    // Add performance and error logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;

          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            if (duration > 2000) {
              if (kDebugMode) {
                print(
                  '⚠️ SLOW API: ${response.requestOptions.path} took ${duration}ms',
                );
              }
            } else {
              if (kDebugMode) {
                print(
                  '✅ API: ${response.requestOptions.path} took ${duration}ms',
                );
              }
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          // Performance logging for errors (simplified)
          handler.next(error);
        },
      ),
    );
  }

  // Register device token for push notifications
  Future<Map<String, dynamic>> registerDevice({
    required String employeeId,
    required String token,
    required String platform,
    String? appVersion,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerDevice,
        data: {
          'employeeId': employeeId,
          'token': token,
          'platform': platform,
          if (appVersion != null) 'appVersion': appVersion,
        },
      );
      return {
        'success': response.statusCode == 200,
        'data': response.data,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Unregister device token (on logout)
  Future<Map<String, dynamic>> unregisterDevice({
    required String token,
  }) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.unregisterDevice}/$token');
      return {
        'success': response.statusCode == 200,
        'data': response.data,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get unread count for notifications
  Future<int> getUnreadCount(String employeeId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.unreadCount}/$employeeId');
      if (response.statusCode == 200) {
        return (response.data['unread'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // Check if email already exists
  Future<Map<String, dynamic>> checkEmailExists({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkEmailExists,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'exists':
              response.data['emailExists'] ??
              false, // Changed from 'exists' to 'emailExists'
          'message': response.data['message'] ?? 'Email check completed',
        };

        return result;
      } else {
        return {
          'success': false,
          'exists': false,
          'message': 'Email check failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'exists': false,
          'message': e.response?.data['message'] ?? 'Email check failed',
        };
      } else {
        return {
          'success': false,
          'exists': false,
          'message': 'Network error: ${e.message}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'exists': false,
        'message': 'Unexpected error: $e',
      };
    }
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

  // Login user with mobile API (new endpoint)
  Future<Map<String, dynamic>> loginUserMobile({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.loginUserMobile,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        // Return the API response directly
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Mobile login failed: ${response.statusCode}',
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

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String employeeId,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'employeeId': employeeId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );

      if (response.statusCode == 200) {
        // ✅ Ensure response.data is always a Map
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Password change failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // ✅ Ensure response.data is always a Map, not a String
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else if (responseData is String) {
          return {
            'success': false,
            'message': responseData,
          };
        } else {
          return {
            'success': false,
            'message': 'Password change failed: ${e.response!.statusCode}',
          };
        }
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
      // Use the original endpoint with employeeId for now
      // TODO: Backend should implement /employee/profile endpoint for current user
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

  // Get employee shift by date
  Future<Map<String, dynamic>> getEmployeeShiftByDate({
    required String employeeId,
    required String date, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.employeeShiftByDate}',
        queryParameters: {
          'employeeId': employeeId,
          'date': date,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get employee shift: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Failed to get employee shift',
          'error': e.response?.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Network error: ${e.message}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get employee shift: ${e.toString()}',
      };
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

  // Get shift data with filter
  Future<Map<String, dynamic>> getShiftDataWithFilter({
    required String employeeId,
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/employee/shift-data/filter',
        queryParameters: {'employeeId': employeeId, 'date': date},
      );

      if (response.statusCode == 200) {
        // Return the API response directly since it already has the correct structure
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get shift data: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Failed to get shift data',
          'error': e.response?.data,
        };
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

  // Get attendance list with month/year filter
  Future<Map<String, dynamic>> getAttendanceListWithFilter({
    required String employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'employeeId': employeeId,
      };
      
      if (month != null) {
        queryParams['month'] = month;
      }
      if (year != null) {
        queryParams['year'] = year;
      }

      final response = await _dio.get(
        '${ApiEndpoints.myAttendanceHistory}/$employeeId',
        queryParameters: queryParams,
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
    } on DioException catch (e) {
      if (e.response != null) {
        // Handle specific HTTP status codes
        if (e.response!.statusCode == 404) {
          return {
            'success': false,
            'message': 'No attendance records found for the specified period',
          };
        } else if (e.response!.statusCode == 400) {
          return {
            'success': false,
            'message': 'Invalid request parameters',
          };
        } else {
          return {
            'success': false,
            'message': e.response?.data['message'] ?? 'Failed to get attendance list',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${e.message}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get attendance list: ${e.toString()}',
      };
    }
  }

  // Search attendance by employee name with month/year filter
  Future<Map<String, dynamic>> searchAttendanceByName({
    required String name,
    int? year,
    int? month,
    String? date,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'name': name,
        'limit': limit,
      };
      
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (month != null) {
        queryParams['month'] = month.toString();
      }
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.searchAttendanceByName}',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to search attendance: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Failed to search attendance',
          'error': e.response?.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Network error: ${e.message}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search attendance: ${e.toString()}',
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
    double? latitude,
    double? longitude,
    String? address,
    String? checkInLocation,
  }) async {
    try {
      final data = <String, dynamic>{
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
      };

      // Add GPS coordinates if provided
      if (latitude != null) {
        data['latitude'] = latitude;
      }
      if (longitude != null) {
        data['longitude'] = longitude;
      }
      if (address != null) {
        data['address'] = address;
      }
      if (checkInLocation != null) {
        data['checkInLocation'] = checkInLocation;
      }

      final response = await _dio.post(ApiEndpoints.checkInOut, data: data);

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
