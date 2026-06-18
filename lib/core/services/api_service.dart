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

   
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
        
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('user_token');

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Error getting token handled silently
          }
          handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
         
          if (error.response?.statusCode == 401) {
            try {
             
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('logged_in', false);
              await prefs.remove('user_token');
              await prefs.remove('user_id');
              await prefs.remove('employee_id');
            } catch (e) {
              // Error clearing expired token handled silently
            }
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          if (kDebugMode) {
            print('🚀 [API Request] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            final method = response.requestOptions.method;
            final uri = response.requestOptions.uri.toString();
            if (kDebugMode) {
              print('✅ [API Response] $method $uri - ${duration}ms (Status: ${response.statusCode})');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          final startTime = error.requestOptions.extra['startTime'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            final method = error.requestOptions.method;
            final uri = error.requestOptions.uri.toString();
            final statusCode = error.response?.statusCode ?? 'N/A';
            if (kDebugMode) {
              print('❌ [API Error] $method $uri - ${duration}ms (Status: $statusCode)');
            }
          }
          handler.next(error);
        },
      ),
    );
  }

 
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
              false, 
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
       
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
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
       
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Mobile login failed: ${response.statusCode}',
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

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
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
          'message': 'Forgot password request failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
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
            'message': 'Forgot password failed: ${e.response!.statusCode}',
          };
        }
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }


  Future<Map<String, dynamic>> verifyResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyResetOTP,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
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
          'message': 'OTP verification failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
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
            'message': 'OTP verification failed: ${e.response!.statusCode}',
          };
        }
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
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
          'message': 'Password reset failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
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
            'message': 'Password reset failed: ${e.response!.statusCode}',
          };
        }
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }


  Future<Map<String, dynamic>> getEmployeeProfile({
    required String employeeId,
  }) async {
    try {
      
      final response = await _dio.get(
        '${ApiEndpoints.employeeProfile}/$employeeId',
      );

      if (response.statusCode == 200) {
       
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get employee profile: ${response.statusCode}',
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

  Future<Map<String, dynamic>> getEmployeeProfileByUid(String uid) async {
    try {
      final response = await _dio.get(
        '/profile/$uid',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Failed to get employee profile: ${response.statusCode}',
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

  Future<Map<String, dynamic>> getEmployeeShiftByDate({
    required String employeeId,
    required String date, 
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

  Future<Map<String, dynamic>> getTodayAttendanceStatus({
    required String employeeId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.attendanceStatus}/$employeeId',
      );

      if (response.statusCode == 200) {
       
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

        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> getShiftDataWithFilter({
    required String employeeId,
    required String date,
  }) async {
    // Try new endpoint first, fallback to old one
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/employee/shift-data/filter-updated',
        queryParameters: {'employeeId': employeeId, 'date': date},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      // If new endpoint fails, try old endpoint
      if (kDebugMode) {
        print('⚠️ New endpoint failed, trying old endpoint: ${e.message}');
      }
    } catch (e) {
      // If new endpoint fails, try old endpoint
      if (kDebugMode) {
        print('⚠️ New endpoint failed, trying old endpoint: ${e.toString()}');
      }
    }

    // Fallback to old endpoint
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/employee/shift-data/filter',
        queryParameters: {'employeeId': employeeId, 'date': date},
      );

      if (response.statusCode == 200) {
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
      return {'success': false, 'message': 'Failed to get shift data: ${e.toString()}'};
    }
  }

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

  Future<Map<String, dynamic>> getShiftCalendar({
    required String employeeId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getShiftCalendar(employeeId, fromDate, toDate),
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get shift calendar: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Failed to get shift calendar',
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
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

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
    required String type, 
    double? latitude,
    double? longitude,
    String? address,
    String? checkInLocation,
    String? checkOutLocation,
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
      if (checkOutLocation != null) {
        data['checkOutLocation'] = checkOutLocation;
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

  Future<Map<String, dynamic>> checkInOutWithRecordData(
    Map<String, dynamic> recordData,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkInOut,
        data: recordData,
      );

      if (response.statusCode == 200) {
        // Check if the response data indicates success
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // If server returns success field, use it
          if (responseData.containsKey('success')) {
            return {
              'success': responseData['success'] == true,
              'data': responseData,
              'message': responseData['message'] ?? 
                (responseData['success'] == true 
                  ? 'Check in/out successful' 
                  : 'Check in/out failed'),
            };
          }
        }
        
        // Default: assume success if status is 200
        return {
          'success': true,
          'data': responseData,
          'message': 'Check in/out successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Check in/out failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Check-out API error: ${e.message}');
        debugPrint('Response data: ${e.response?.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 
          e.response?.data['error'] ?? 
          'Check in/out failed: ${e.message}',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Check-out unexpected error: $e');
      }
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
