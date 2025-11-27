import 'package:dio/dio.dart';

class ErrorHandler {
  static String handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 401) {
          return 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          return 'Access denied.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Request failed with status: $statusCode';
        }
      
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      
      case DioExceptionType.badCertificate:
        return 'Security certificate error.';
      
      case DioExceptionType.unknown:
        return error.message ?? 'An unknown error occurred.';
    }
  }
  
  static String handleException(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    }
    
    if (error is FormatException) {
      return 'Data format error. Please try again.';
    }
    
    if (error is TypeError) {
      return 'Data type error. Please contact support.';
    }
    
    return error.toString().isNotEmpty 
        ? error.toString() 
        : 'An unexpected error occurred.';
  }
  
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }
  
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401 || 
             error.response?.statusCode == 403;
    }
    return false;
  }
}
