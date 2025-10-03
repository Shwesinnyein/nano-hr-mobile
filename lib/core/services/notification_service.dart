import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_endpoints.dart';

class NotificationService {
  final Dio _dio = Dio();

  // Cache for notifications
  static Map<String, List<dynamic>> _notificationCache = {};
  static DateTime? _cacheTimestamp;
  static const int _cacheExpiryMinutes = 5;

  // Check if cache is valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamp!).inMinutes;
    return difference < _cacheExpiryMinutes;
  }

  // Clear cache
  void clearCache() {
    _notificationCache.clear();
    _cacheTimestamp = null;
  }

  // Get all notifications for a user
  Future<Map<String, dynamic>> getNotifications({
    required String employeeId,
    int? limit,
    int? page,
    bool? unreadOnly,
  }) async {
    try {
      // Check cache first
      if (_isCacheValid() && _notificationCache.containsKey(employeeId)) {
        print('🔔 Notification API: Using cached data for $employeeId');
        return {
          'success': true,
          'data': _notificationCache[employeeId],
          'message': 'Cached notifications',
        };
      }
      final endpoint =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.getUserNotifications}/$employeeId';
      print(
        '🔔 Notification API: Getting notifications for employee: $employeeId',
      );
      print('🔔 Notification API: Endpoint: $endpoint');

      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly;

      print('🔔 Notification API: Query params: $queryParams');

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('🔔 Notification API: Response status: ${response.statusCode}');
      print('🔔 Notification API: Response headers: ${response.headers}');
      print('🔔 Notification API: Response data: ${response.data}');
      print(
        '🔔 Notification API: Response data type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200) {
        // Ensure response.data is a Map, not a String
        if (response.data is String) {
          print('🔔 Notification API: Response is String, parsing JSON...');
          try {
            final Map<String, dynamic> parsedData = jsonDecode(response.data);
            return parsedData;
          } catch (e) {
            print('🔔 Notification API: JSON parsing error: $e');
            return {
              'success': false,
              'message': 'Failed to parse JSON response: $e',
              'data': [],
            };
          }
        } else if (response.data is Map) {
          print('🔔 Notification API: Response is already a Map');
          final result = Map<String, dynamic>.from(response.data);

          // Cache the result
          if (result['data'] is List) {
            _notificationCache[employeeId] = result['data'];
            _cacheTimestamp = DateTime.now();
            print('🔔 Notification API: Cached notifications for $employeeId');
          }

          return result;
        } else {
          print(
            '🔔 Notification API: Unexpected response type: ${response.data.runtimeType}',
          );
          return {
            'success': false,
            'message':
                'Unexpected response format: ${response.data.runtimeType}',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch notifications: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('🔔 Notification API: DioException - ${e.message}');
      if (e.response != null) {
        print('🔔 Notification API: Error response: ${e.response!.data}');

        // Handle 404 - notification endpoints might not exist yet
        if (e.response!.statusCode == 404) {
          print(
            '🔔 Notification API: Endpoint not found (404) - notification endpoints may not be implemented yet',
          );
          return {
            'success': true,
            'message': 'No notifications found',
            'data': [],
            'pagination': {
              'totalNotifications': 0,
              'totalPages': 0,
              'currentPage': 1,
              'limit': 20,
            },
          };
        }

        // Ensure error response is also properly typed
        if (e.response!.data is String) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e.response!.data));
          } catch (parseError) {
            print(
              '🔔 Notification API: Error parsing error response: $parseError',
            );
            return {
              'success': false,
              'message': 'Network error: ${e.message}',
              'data': [],
            };
          }
        } else if (e.response!.data is Map) {
          return Map<String, dynamic>.from(e.response!.data);
        } else {
          return {
            'success': false,
            'message': 'Network error: ${e.message}',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Network error: ${e.message}',
          'data': [],
        };
      }
    } catch (e) {
      print('🔔 Notification API: Unexpected error - $e');
      return {'success': false, 'message': 'Unexpected error: $e', 'data': []};
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead({
    required String employeeId,
    required String notificationId,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.markNotificationRead}/$employeeId/read/$notificationId',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message':
              'Failed to mark notification as read: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          return {
            'success': true,
            'message':
                'Notification endpoint not implemented yet - marked as read locally',
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

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead({
    required String employeeId,
  }) async {
    try {
      print(
        '🔔 Notification API: Marking all notifications as read for employee: $employeeId',
      );

      // Get all unread notifications first
      final notificationsResponse = await getNotifications(
        employeeId: employeeId,
        unreadOnly: true,
      );

      if (notificationsResponse['success'] != true) {
        return notificationsResponse;
      }

      final notifications = notificationsResponse['data'] as List<dynamic>;
      int successCount = 0;
      int failCount = 0;

      // Mark each notification as read
      for (final notification in notifications) {
        final notificationId = notification['id'] as String;
        final result = await markAsRead(
          employeeId: employeeId,
          notificationId: notificationId,
        );

        if (result['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      }

      return {
        'success': true,
        'message':
            'Marked $successCount notifications as read. $failCount failed.',
        'successCount': successCount,
        'failCount': failCount,
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
}
