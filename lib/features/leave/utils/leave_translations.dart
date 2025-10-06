import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/translation_helper.dart';

// Leave-specific translation helper
class LeaveTranslations {
  // Leave screen titles and labels
  static String leaveManagement(WidgetRef ref) =>
      ref.t('จัดการการลา', 'Leave Management');

  static String viewLeaveList(WidgetRef ref) =>
      ref.t('ดูรายการลา', 'View Leave List');

  static String teamLeaveManagement(WidgetRef ref) =>
      ref.t('จัดการการลาของทีม', 'Team Leave Management');

  static String teamLeaveApprovals(WidgetRef ref) =>
      ref.t('อนุมัติการลาของทีม', 'Team Leave Approvals');

  static String approveAndManageTeam(WidgetRef ref) => ref.t(
    'อนุมัติและจัดการคำขอลาของทีมของคุณ',
    'Approve and manage your team\'s leave requests',
  );

  static String leaveTypes(WidgetRef ref) =>
      ref.t('ประเภทการลา', 'Leave Types');

  static String recentRequests(WidgetRef ref) =>
      ref.t('คำขอลาล่าสุด', 'Recent Requests');

  // Leave type names
  static String annualLeave(WidgetRef ref) =>
      ref.t('ลาพักผ่อนประจำปี', 'Annual Leave');

  static String sickLeave(WidgetRef ref) => ref.t('ลาป่วย', 'Sick Leave');

  static String personalLeave(WidgetRef ref) =>
      ref.t('ลาส่วนตัว', 'Personal Leave');

  static String unpaidLeave(WidgetRef ref) =>
      ref.t('ลา (โดยไม่ได้รับค่าจ้าง)', 'Unpaid Leave');

  static String paidPersonalLeave(WidgetRef ref) =>
      ref.t('ลากิจ(ได้รับค่าจ้าง)', 'Paid Personal Leave');

  static String militaryLeave(WidgetRef ref) =>
      ref.t('ลา (เพื่อรับราชการทหาร)', 'Military Leave');

  static String sterilizationLeave(WidgetRef ref) =>
      ref.t('ลา (เพื่อทำหมัน)', 'Sterilization Leave');

  static String funeralLeave(WidgetRef ref) =>
      ref.t('ลา (เพื่อจัดงานฌาปนกิจ)', 'Funeral Leave');

  static String marriageLeave(WidgetRef ref) =>
      ref.t('ลาสมรส', 'Marriage Leave');

  // Status labels
  static String available(WidgetRef ref) => ref.t('พร้อมใช้งาน', 'Available');

  static String usedUp(WidgetRef ref) => ref.t('ใช้หมดแล้ว', 'Used Up');

  static String days(WidgetRef ref) => ref.t('วัน', 'days');

  static String used(WidgetRef ref) => ref.t('ใช้แล้ว', 'used');

  // Leave request screen
  static String leaveRequest(WidgetRef ref) => ref.t('คำขอลา', 'Leave Request');

  static String selectLeaveType(WidgetRef ref) =>
      ref.t('เลือกประเภทการลา', 'Select Leave Type');

  static String selectDates(WidgetRef ref) =>
      ref.t('เลือกวันที่', 'Select Dates');

  static String reason(WidgetRef ref) => ref.t('เหตุผล', 'Reason');

  static String attachments(WidgetRef ref) => ref.t('เอกสารแนบ', 'Attachments');

  static String submitRequest(WidgetRef ref) =>
      ref.t('ส่งคำขอ', 'Submit Request');

  static String cancel(WidgetRef ref) => ref.t('ยกเลิก', 'Cancel');

  static String startDate(WidgetRef ref) =>
      ref.t('วันที่เริ่มต้น', 'Start Date');

  static String endDate(WidgetRef ref) => ref.t('วันที่สิ้นสุด', 'End Date');

  static String totalDays(WidgetRef ref) =>
      ref.t('จำนวนวันทั้งหมด', 'Total Days');

  static String pleaseEnterReason(WidgetRef ref) =>
      ref.t('กรุณาใส่เหตุผล', 'Please enter reason');

  static String selectStartDate(WidgetRef ref) =>
      ref.t('เลือกวันที่เริ่มต้น', 'Select start date');

  static String selectEndDate(WidgetRef ref) =>
      ref.t('เลือกวันที่สิ้นสุด', 'Select end date');

  // Leave list screen
  static String leaveHistory(WidgetRef ref) =>
      ref.t('ประวัติการลา', 'Leave History');

  static String allRequests(WidgetRef ref) =>
      ref.t('คำขอทั้งหมด', 'All Requests');

  static String pending(WidgetRef ref) => ref.t('รอดำเนินการ', 'Pending');

  static String approved(WidgetRef ref) => ref.t('อนุมัติ', 'Approved');

  static String rejected(WidgetRef ref) => ref.t('ปฏิเสธ', 'Rejected');

  static String noLeaveRequests(WidgetRef ref) =>
      ref.t('ไม่มีคำขอลา', 'No leave requests');

  // Leave approval screen
  static String leaveApproval(WidgetRef ref) =>
      ref.t('อนุมัติการลา', 'Leave Approval');

  static String pendingApprovals(WidgetRef ref) =>
      ref.t('รอการอนุมัติ', 'Pending Approvals');

  static String approve(WidgetRef ref) => ref.t('อนุมัติ', 'Approve');

  static String reject(WidgetRef ref) => ref.t('ปฏิเสธ', 'Reject');

  static String addComment(WidgetRef ref) =>
      ref.t('เพิ่มความคิดเห็น', 'Add Comment');

  static String employeeName(WidgetRef ref) =>
      ref.t('ชื่อพนักงาน', 'Employee Name');

  static String position(WidgetRef ref) => ref.t('ตำแหน่ง', 'Position');

  static String department(WidgetRef ref) => ref.t('แผนก', 'Department');

  // Error messages
  static String errorLoadingLeaveData(WidgetRef ref) =>
      ref.t('เกิดข้อผิดพลาดในการโหลดข้อมูลการลา', 'Error loading leave data');

  static String failedToLoadLeaveBalance(WidgetRef ref) => ref.t(
    'ไม่สามารถโหลดข้อมูลการลาที่เหลือได้',
    'Failed to load leave balance',
  );

  static String userNotLoggedIn(WidgetRef ref) =>
      ref.t('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ', 'User not logged in');

  static String noDataAvailable(WidgetRef ref) =>
      ref.t('ไม่มีข้อมูล', 'No data available');

  static String noEmployeesAvailable(WidgetRef ref) =>
      ref.t('ไม่มีพนักงาน', 'No employees available');

  // Success messages
  static String leaveRequestSubmitted(WidgetRef ref) =>
      ref.t('ส่งคำขอลาเรียบร้อยแล้ว', 'Leave request submitted successfully');

  static String leaveRequestApproved(WidgetRef ref) => ref.t(
    'อนุมัติคำขอลาเรียบร้อยแล้ว',
    'Leave request approved successfully',
  );

  static String leaveRequestRejected(WidgetRef ref) =>
      ref.t('ปฏิเสธคำขอลาเรียบร้อยแล้ว', 'Leave request rejected');

  // Common terms
  static String loading(WidgetRef ref) => ref.t('กำลังโหลด...', 'Loading...');

  static String retry(WidgetRef ref) => ref.t('ลองใหม่', 'Retry');

  static String refresh(WidgetRef ref) => ref.t('รีเฟรช', 'Refresh');

  static String back(WidgetRef ref) => ref.t('กลับ', 'Back');

  static String next(WidgetRef ref) => ref.t('ถัดไป', 'Next');

  static String save(WidgetRef ref) => ref.t('บันทึก', 'Save');

  static String edit(WidgetRef ref) => ref.t('แก้ไข', 'Edit');

  static String delete(WidgetRef ref) => ref.t('ลบ', 'Delete');

  static String confirm(WidgetRef ref) => ref.t('ยืนยัน', 'Confirm');

  static String yes(WidgetRef ref) => ref.t('ใช่', 'Yes');

  static String no(WidgetRef ref) => ref.t('ไม่', 'No');

  // Search and filter translations
  static String searchByEmployeeLeaveTypeReason(WidgetRef ref) => ref.t(
    'ค้นหาตามชื่อพนักงาน ประเภทการลา หรือเหตุผล...',
    'Search by employee, leave type, or reason...',
  );

  static String noPendingRequests(WidgetRef ref) =>
      ref.t('ไม่มีคำขอที่รอดำเนินการ', 'No pending requests');

  static String noApprovedRequests(WidgetRef ref) =>
      ref.t('ไม่มีคำขอที่อนุมัติแล้ว', 'No approved requests');

  static String noRejectedRequests(WidgetRef ref) =>
      ref.t('ไม่มีคำขอที่ปฏิเสธแล้ว', 'No rejected requests');

  // Helper method to translate leave type names dynamically
  static String translateLeaveTypeName(WidgetRef ref, String typeName) {
    final name = typeName.toLowerCase();

    if (name.contains('annual') || name.contains('ลาพักผ่อน')) {
      return annualLeave(ref);
    } else if (name.contains('ป่วย') || name.contains('sick')) {
      return sickLeave(ref);
    } else if (name.contains('ไม่ได้รับค่าจ้าง') || name.contains('unpaid')) {
      return unpaidLeave(ref);
    } else if (name.contains('ลากิจ') || name.contains('paid personal')) {
      return paidPersonalLeave(ref);
    } else if (name.contains('ทหาร') || name.contains('military')) {
      return militaryLeave(ref);
    } else if (name.contains('ทำหมัน') || name.contains('sterilization')) {
      return sterilizationLeave(ref);
    } else if (name.contains('ฌาปนกิจ') || name.contains('funeral')) {
      return funeralLeave(ref);
    } else if (name.contains('สมรส') || name.contains('marriage')) {
      return marriageLeave(ref);
    } else if (name.contains('ส่วนตัว') || name.contains('personal')) {
      return personalLeave(ref);
    }

    // Default: return original name if no match found
    return typeName;
  }

  // Helper method to translate status
  static String translateStatus(WidgetRef ref, String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.contains('approved')) {
      return approved(ref);
    } else if (statusLower.contains('rejected')) {
      return rejected(ref);
    } else if (statusLower.contains('pending')) {
      return pending(ref);
    }

    // Default: return original status
    return status;
  }
}
