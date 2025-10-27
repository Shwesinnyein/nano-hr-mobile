class ApiEndpoints {
  static const String baseUrl = 'https://nano-hr-api.vercel.app';

  // Auth endpoints
  static const String loginUser = '/auth/login-user';
  static const String loginUserMobile = '/auth/mobile-login';
  static const String registerUser = '/auth/register-user';
  static const String checkEmailExists = '/auth/check-email';

  // Attendance endpoints
  static const String checkInOut = '/attendance/check-in-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceList = '/attendance/history';
  static const String myAttendanceHistory = '/attendance/my-history';
  static const String searchAttendanceByName = '/attendance/search-by-name';

  // Employee endpoints
  static const String employeeProfile =
      '/employee/profile'; // Gets employee profile by ID
  static const String updateProfile = '/employee/update-profile';
  static const String employeeList = '/employee/list';
  static const String employeeShiftByDate = '/employee/shift/get-by-date';

  // Leave endpoints
  static const String createLeaveRequest = '/leave/create';
  static const String leaveRequests = '/leave/employee';
  static const String leaveBalance = '/leave/balance';
  static const String leaveSettings = '/leave/settings';
  // Approval endpoints for different levels
  static String getLeaveRequestsForApproval(String level, String userId) =>
      '/leave/approval/pending?level=$level&userId=$userId';
  // Leave history endpoint for employee leaves tab
  static String getLeaveHistory(String userId) =>
      '/leave/history?userId=$userId';
  // GET /leave/{leaveId}
  static String leaveDetails(String leaveId) => '/leave/$leaveId';
  // Leave approval endpoints (server supports either path)
  // PUT /leave/{leaveId}/status
  static String leaveStatus(String leaveId) => '/leave/$leaveId/status';
  // PUT /leave/approval/{leaveId}
  static String leaveApproval(String leaveId) => '/leave/approval/$leaveId';

  // File upload endpoints
  static const String uploadFile = '/upload/file';

  // Notification endpoints
  static const String getUserNotifications =
      '/notifications'; // GET /notifications/{employeeId}
  static const String markNotificationRead =
      '/notifications'; // PUT /notifications/{employeeId}/read/{notificationId}
}
