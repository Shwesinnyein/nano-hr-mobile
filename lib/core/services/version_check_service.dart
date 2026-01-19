import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../api/api_endpoints.dart';

class VersionCheckService {
  final Dio _dio = Dio();

  VersionCheckService() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Check if update is required by calling the API
  /// Returns: { 'shouldUpdate': bool, 'isMandatory': bool, 'latestVersion': String, 'currentVersion': String, 'updateUrl': Map, 'updateMessage': String, 'updateMessageTh': String }
  Future<Map<String, dynamic>> checkForUpdate({
    required String minAppVersion,
  }) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      if (kDebugMode) {
        debugPrint('📱 [VersionCheck] Current app version: $currentVersion');
        debugPrint('📱 [VersionCheck] Calling API: ${ApiEndpoints.appVersion}?currentVersion=$currentVersion');
      }

      // Call API with currentVersion as query parameter
      // Expected response: { "success": true, "data": { "latestVersion": "1.1.1", "minAppVersion": "1.1.1", "updateAvailable": true, "forceUpdate": true, ... } }
      final response = await _dio.get(
        ApiEndpoints.appVersion,
        queryParameters: {
          'currentVersion': currentVersion,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          final updateAvailable = data['updateAvailable'] as bool? ?? false;
          final forceUpdate = data['forceUpdate'] as bool? ?? false;
          final latestVersion = data['latestVersion'] as String? ?? currentVersion;
          final updateUrl = data['updateUrl'] as Map<String, dynamic>?;
          final updateMessage = data['updateMessage'] as String?;
          final updateMessageTh = data['updateMessageTh'] as String?;
          
          if (kDebugMode) {
            debugPrint('📱 [VersionCheck] Latest version: $latestVersion');
            debugPrint('📱 [VersionCheck] Update available: $updateAvailable');
            debugPrint('📱 [VersionCheck] Force update: $forceUpdate');
          }

          return {
            'shouldUpdate': updateAvailable,
            'isMandatory': forceUpdate,
            'latestVersion': latestVersion,
            'currentVersion': currentVersion,
            'updateUrl': updateUrl,
            'updateMessage': updateMessage,
            'updateMessageTh': updateMessageTh,
          };
        }
      }

      // If API fails, fallback to minAppVersion check
      if (kDebugMode) {
        debugPrint('⚠️ [VersionCheck] API response invalid, using fallback');
      }
      
      final isMandatory = _compareVersions(currentVersion, minAppVersion) < 0;
      return {
        'shouldUpdate': isMandatory,
        'isMandatory': isMandatory,
        'latestVersion': minAppVersion,
        'currentVersion': currentVersion,
        'updateUrl': null,
        'updateMessage': null,
        'updateMessageTh': null,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VersionCheck] API error: ${e.message}');
        if (e.response != null) {
          debugPrint('❌ [VersionCheck] Response: ${e.response?.data}');
        }
      }
      
      // Fallback: check against minAppVersion only
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final isMandatory = _compareVersions(currentVersion, minAppVersion) < 0;
      
      return {
        'shouldUpdate': isMandatory,
        'isMandatory': isMandatory,
        'latestVersion': minAppVersion,
        'currentVersion': currentVersion,
        'updateUrl': null,
        'updateMessage': null,
        'updateMessageTh': null,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VersionCheck] Error: $e');
      }
      
      // Fallback: check against minAppVersion only
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final isMandatory = _compareVersions(currentVersion, minAppVersion) < 0;
      
      return {
        'shouldUpdate': isMandatory,
        'isMandatory': isMandatory,
        'latestVersion': minAppVersion,
        'currentVersion': currentVersion,
        'updateUrl': null,
        'updateMessage': null,
        'updateMessageTh': null,
      };
    }
  }

  /// Compare two version strings (e.g., "1.1.1" vs "1.1.2")
  /// Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.tryParse).toList();
    final v2Parts = version2.split('.').map(int.tryParse).toList();

    // Ensure both have the same number of parts
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      final v1 = v1Parts[i] ?? 0;
      final v2 = v2Parts[i] ?? 0;
      
      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }
    
    return 0;
  }
}

