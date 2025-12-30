class ApiEndpoints {
//   static const String baseUrl = 'https://nano-hr-api.vercel.app';
static const String baseUrl = 'https://nano-api-production.vercel.app';

  // Auth endpoints
  static const String loginUser = '/auth/login-user';
  static const String loginUserMobile = '/auth/mobile-login';
  static const String registerUser = '/auth/register-user';
  static const String checkEmailExists = '/auth/check-email';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOTP = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // Attendance endpoints
  static const String checkInOut = '/attendance/check-in-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceList = '/attendance/history';
  static const String myAttendanceHistory = '/attendance/my-history';
  static const String searchAttendanceByName = '/attendance/search-by-name';

  // Employee endpoints
  static const String employeeProfile ='/employee/profile';
  static String getEmployeeProfileByUid(String uid) => '/profile/$uid'; 
  static const String updateProfile = '/employee/update-profile';
  static const String employeeList = '/employee/list';
  static const String employeeShiftByDate = '/employee/shift/get-by-date';
  static String getShiftCalendar(String employeeId, String fromDate, String toDate) =>
      '/employee/$employeeId/shift-calendar?fromDate=$fromDate&toDate=$toDate';

  // Leave endpoints
  static const String createLeaveRequest = '/leave/create';
  static const String leaveRequests = '/leave/employee';
  static const String leaveBalance = '/leave/balance';
  static const String leaveSettings = '/leave/settings';
 
  static String getLeaveRequestsForApproval(String level, String userId) =>
      '/leave/approval/pending?level=$level&userId=$userId';
 
  static String getLeaveHistory(String userId) =>
      '/leave/history?userId=$userId';
 
  static String leaveDetails(String leaveId) => '/leave/$leaveId';
  
  static String leaveStatus(String leaveId) => '/leave/$leaveId/status';
  
  static String leaveApproval(String leaveId) => '/leave/approval/$leaveId';

  static const String uploadFile = '/upload/file';

  static const String getUserNotifications =
      '/notifications'; 
  static const String markNotificationRead =
      '/notifications'; 
  static const String registerDevice = '/notifications/devices/register';
  static const String unregisterDevice = '/notifications/devices';
  static const String unreadCount = '/notifications/unread-count';
}
