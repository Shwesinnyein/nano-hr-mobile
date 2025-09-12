class ApiEndpoints {
  static const String baseUrl = 'https://nano-hr-api.vercel.app';

  // Auth endpoints
  static const String loginUser = '/auth/login-user';
  static const String registerUser = '/auth/register-user';

  // Attendance endpoints
  static const String checkInOut = '/attendance/check-in-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceList = '/attendance';

  // Employee endpoints
  static const String employeeProfile = '/employee/profile';
  static const String updateProfile = '/employee/update-profile';

  // Leave endpoints
  static const String createLeaveRequest = '/leave/create-request';
  static const String leaveRequests = '/leave/requests';
  static const String leaveBalance = '/leave/balance';

  // File upload endpoints
  static const String uploadFile = '/upload/file';
}
