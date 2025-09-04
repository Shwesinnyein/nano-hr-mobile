class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyToken = '/auth/verify';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';

  // Employee endpoints
  static const String employees = '/employee/list';
  static const String employeeById = '/employee/{id}';
  static const String employeeByUid = '/employee/profile/{uid}';
  static const String employeeDirectory = '/employee/directory';

  // Employee authentication endpoints
  static const String employeeCheckEmail = '/api/employee/check-email';
  static const String employeeSetPassword = '/api/employee/set-password';
  static const String employeeLogin = '/api/employee/login';

  // Pagination support for employees
  static String getEmployeesPaginated({int page = 1, int limit = 20}) {
    return '$employees?page=$page&limit=$limit';
  }

  // Leave endpoints
  static const String leaveBalance = '/leave/balance';
  static const String leaveRequests = '/leave/requests';
  static const String submitLeaveRequest = '/leave/requests';
  static const String createLeaveRequest = '/employee/create-leave-request';
  static const String leaveRequestById = '/leave/requests/{id}';
  static const String leaveTypes = '/leave/types';
  static const String leaveSettings = '/leave/settings';
  static const String employeeLeaveList = '/employee/leave-list/{employeeId}';

  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceReports = '/attendance/reports';

  // Organization endpoints
  static const String companyInfo = '/organization/company';
  static const String departments = '/organization/departments';
  static const String departmentStructure = '/organization/structure';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Settings endpoints
  static const String settings = '/settings';
  static const String updateSettings = '/settings';

  // File upload endpoints
  static const String uploadFile = '/upload';
  static const String uploadProfileImage = '/upload/profile-image';
  static const String uploadDocument = '/upload/document';

  // Replace placeholder with actual ID
  static String getEmployeeById(String id) =>
      employeeById.replaceAll('{id}', id);
  static String getEmployeeByUid(String uid) =>
      employeeByUid.replaceAll('{uid}', uid);
  static String getLeaveRequestById(String id) =>
      leaveRequestById.replaceAll('{id}', id);
  static String markNotificationAsRead(String id) =>
      markNotificationRead.replaceAll('{id}', id);
  static String getEmployeeLeaveList(String employeeId) =>
      employeeLeaveList.replaceAll('{employeeId}', employeeId);
}
