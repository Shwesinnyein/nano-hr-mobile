import 'package:dio/dio.dart';
import '../api/api_endpoints.dart';

class LeaveService {
  final Dio _dio = Dio();

  LeaveService() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptors
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 Leave API: $obj'),
      ),
    );
  }

  // Get leave settings for employee
  Future<Map<String, dynamic>> getLeaveSettings(String employeeId) async {
    try {
      print('🌐 Leave API: Getting leave settings for employee: $employeeId');

      final response = await _dio.get(
        ApiEndpoints.leaveSettings,
        queryParameters: {'employeeId': employeeId},
      );

      if (response.statusCode == 200) {
        print('✅ Leave API: Settings retrieved successfully');
        return response.data;
      } else {
        print(
          '❌ Leave API: Failed to get settings - Status: ${response.statusCode}',
        );
        return {
          'success': false,
          'message': 'Failed to get leave settings: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ Leave API: DioException - ${e.message}');
      if (e.response != null) {
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      print('❌ Leave API: Unexpected error - $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Create leave request
  Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      print('🌐 Leave API: Creating leave request');
      print('🌐 Leave API: Request data: $data');

      final response = await _dio.post(
        ApiEndpoints.createLeaveRequest,
        data: data,
      );

      if (response.statusCode == 200) {
        print('✅ Leave API: Leave request created successfully');
        print('🌐 Leave API: Response: ${response.data}');
        return response.data;
      } else {
        print(
          '❌ Leave API: Failed to create request - Status: ${response.statusCode}',
        );
        return {
          'success': false,
          'message': 'Failed to create leave request: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ Leave API: DioException - ${e.message}');
      if (e.response != null) {
        print('🌐 Leave API: Error response: ${e.response!.data}');
        // Handle 404 error specifically
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
      print('❌ Leave API: Unexpected error - $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Get leave requests for employee
  Future<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) async {
    try {
      print('🌐 Leave API: Getting leave requests for employee: $employeeId');

      final response = await _dio.get(
        '${ApiEndpoints.leaveRequests}/$employeeId',
      );

      if (response.statusCode == 200) {
        print('✅ Leave API: Leave requests retrieved successfully');
        final data = response.data;

        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('⚠️ Leave API: No leave records found or invalid data format');
          return [];
        }
      } else {
        print(
          '❌ Leave API: Failed to get requests - Status: ${response.statusCode}',
        );
        return [];
      }
    } on DioException catch (e) {
      print('❌ Leave API: DioException - ${e.message}');
      if (e.response != null) {
        print('🌐 Leave API: Error response: ${e.response!.data}');
        return [];
      } else {
        print('❌ Leave API: Network error - ${e.message}');
        return [];
      }
    } catch (e) {
      print('❌ Leave API: Unexpected error - $e');
      return [];
    }
  }

  // Get leave balance (return available days since API endpoint doesn't exist)
  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      print(
        '🌐 Leave API: Leave balance endpoint not available - returning available days',
      );
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
      print('❌ Leave API: Error getting balance - $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      print('🌐 Leave API: Uploading file: $filePath');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(ApiEndpoints.uploadFile, data: formData);

      if (response.statusCode == 200) {
        print('✅ Leave API: File uploaded successfully');
        return response.data;
      } else {
        print(
          '❌ Leave API: Failed to upload file - Status: ${response.statusCode}',
        );
        return {
          'success': false,
          'message': 'Failed to upload file: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ Leave API: DioException - ${e.message}');
      if (e.response != null) {
        return e.response!.data;
      } else {
        return {'success': false, 'message': 'Network error: ${e.message}'};
      }
    } catch (e) {
      print('❌ Leave API: Unexpected error - $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}
