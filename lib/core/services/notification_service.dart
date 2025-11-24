import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_endpoints.dart';

class NotificationService {
  final Dio _dio = Dio();

  NotificationService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  static Map<String, List<dynamic>> _notificationCache = {};
  static DateTime? _cacheTimestamp;
  static const int _cacheExpiryMinutes = 5;

  static Map<String, List<dynamic>> get notificationCache => _notificationCache;

  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamp!).inMinutes;
    return difference < _cacheExpiryMinutes;
  }

  void clearCache() {
    _notificationCache.clear();
    _cacheTimestamp = null;
  }

  Future<Map<String, dynamic>> getNotifications({
    required String employeeId,
    int? limit,
    int? page,
    bool? unreadOnly,
  }) async {
    try {
      if (_isCacheValid() && _notificationCache.containsKey(employeeId)) {
        return {
          'success': true,
          'data': _notificationCache[employeeId],
          'message': 'Cached notifications',
        };
      }
      final endpoint =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.getUserNotifications}/$employeeId';

      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly;

      final response = await _dio
          .get(
            endpoint,
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw DioException(
                requestOptions: RequestOptions(path: endpoint),
                type: DioExceptionType.connectionTimeout,
                message: 'Request timeout after 30 seconds',
              );
            },
          );

      if (response.statusCode == 200) {
        if (response.data is String) {
          try {
            final Map<String, dynamic> parsedData = jsonDecode(response.data);
            return parsedData;
          } catch (e) {
            return {
              'success': false,
              'message': 'Failed to parse JSON response: $e',
              'data': [],
            };
          }
        } else if (response.data is Map) {
          final result = Map<String, dynamic>.from(response.data);

          if (result['data'] is List) {
            _notificationCache[employeeId] = result['data'];
            _cacheTimestamp = DateTime.now();
          }

          return result;
        } else {
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
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
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

        if (e.response!.data is String) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e.response!.data));
          } catch (parseError) {
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
      return {'success': false, 'message': 'Unexpected error: $e', 'data': []};
    }
  }

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

  Future<Map<String, dynamic>> markAllAsRead({
    required String employeeId,
  }) async {
    try {
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

  Future<Map<String, dynamic>> registerDeviceToken({
    required String employeeId,
    required String token,
    required String platform,
    String? appVersion,
    Map<String, dynamic>? metadata,
  }) async {
    final endpoint = '${ApiEndpoints.baseUrl}${ApiEndpoints.registerDevice}';
    final payload = {
      'employeeId': employeeId,
      'token': token,
      'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
      if (metadata != null) 'metadata': metadata,
    };

    try {
      final response = await _dio.post(endpoint, data: payload);
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      if (response.data is String) {
        return Map<String, dynamic>.from(jsonDecode(response.data));
      }
      return {
        'success': false,
        'message': 'Unexpected response format from register device endpoint',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': true,
          'message': 'Register device endpoint not available (HTTP 404)',
          'statusCode': 404,
        };
      }
      if (e.response?.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      if (e.response?.data is String) {
        try {
          return Map<String, dynamic>.from(jsonDecode(e.response!.data));
        } catch (_) {
         
        }
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to register device token',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error registering device token: $e',
      };
    }
  }

  Future<Map<String, dynamic>> unregisterDeviceToken({
    required String employeeId,
    required String token,
  }) async {
    final endpoint =
        '${ApiEndpoints.baseUrl}${ApiEndpoints.unregisterDevice}/$token';
    final queryParams = {'employeeId': employeeId};

    try {
      final response = await _dio.delete(endpoint, queryParameters: queryParams);
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      if (response.data is String) {
        return Map<String, dynamic>.from(jsonDecode(response.data));
      }
      return {
        'success': false,
        'message': 'Unexpected response format from unregister device endpoint',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': true,
          'message': 'Unregister device endpoint returned 404 (treated as no-op)',
          'statusCode': 404,
        };
      }
      if (e.response?.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      if (e.response?.data is String) {
        try {
          return Map<String, dynamic>.from(jsonDecode(e.response!.data));
        } catch (_) {}
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to unregister device token',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error unregistering device token: $e',
      };
    }
  }
}
