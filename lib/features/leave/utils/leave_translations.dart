import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/translation_helper.dart';


class LeaveTranslations {
  
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

  
  static String available(WidgetRef ref) => ref.t('พร้อมใช้งาน', 'Available');

  static String usedUp(WidgetRef ref) => ref.t('ใช้หมดแล้ว', 'Used Up');

  static String days(WidgetRef ref) => ref.t('วัน', 'days');

  static String used(WidgetRef ref) => ref.t('ใช้แล้ว', 'used');

  
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

  
  static String leaveHistory(WidgetRef ref) =>
      ref.t('ประวัติการลา', 'Leave History');

  static String allRequests(WidgetRef ref) =>
      ref.t('คำขอทั้งหมด', 'All Requests');

  static String pending(WidgetRef ref) => ref.t('รอดำเนินการ', 'Pending');

  static String approved(WidgetRef ref) => ref.t('อนุมัติ', 'Approved');

  static String rejected(WidgetRef ref) => ref.t('ปฏิเสธ', 'Rejected');

  static String noLeaveRequests(WidgetRef ref) =>
      ref.t('ไม่มีคำขอลา', 'No leave requests');

  
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

  
  static String leaveRequestSubmitted(WidgetRef ref) =>
      ref.t('ส่งคำขอลาเรียบร้อยแล้ว', 'Leave request submitted successfully');

  static String leaveRequestApproved(WidgetRef ref) => ref.t(
    'อนุมัติคำขอลาเรียบร้อยแล้ว',
    'Leave request approved successfully',
  );

  static String leaveRequestRejected(WidgetRef ref) =>
      ref.t('ปฏิเสธคำขอลาเรียบร้อยแล้ว', 'Leave request rejected');

  
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

  
  static String pleaseSelectFromDateFirst(WidgetRef ref) =>
      ref.t('กรุณาเลือกวันที่เริ่มต้นก่อน', 'Please select from date first');

  static String errorPickingImage(WidgetRef ref) =>
      ref.t('เกิดข้อผิดพลาดในการเลือกรูปภาพ', 'Error picking image');

  static String fileSizeTooLarge(WidgetRef ref) =>
      ref.t('ขนาดไฟล์ต้องไม่เกิน 10MB', 'File size must be less than 10MB');

  static String imageAdded(WidgetRef ref) =>
      ref.t('เพิ่มรูปภาพเรียบร้อยแล้ว', 'Image added');

  static String imageUploadedSuccessfully(WidgetRef ref) =>
      ref.t('อัปโหลดรูปภาพสำเร็จ', 'Image uploaded successfully');

  static String errorLoadingImage(WidgetRef ref) =>
      ref.t('ไม่สามารถโหลดรูปภาพ', 'Failed to load image');

  static String maxImagesReached(WidgetRef ref, int max) =>
      ref.t(
        'อัปโหลดรูปภาพได้สูงสุด $max รูป',
        'Maximum $max images allowed',
      );

  static String errorAddingImage(WidgetRef ref) =>
      ref.t('เกิดข้อผิดพลาดในการเพิ่มรูปภาพ', 'Error adding image');

  static String pleaseSelectDates(WidgetRef ref) => ref.t(
    'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด',
    'Please select from and to dates',
  );

  static String pleaseSelectDateTime(WidgetRef ref) => ref.t(
    'กรุณาเลือกวันที่ เวลาเริ่มต้น และเวลาสิ้นสุด',
    'Please select date, start time, and end time',
  );

  static String endTimeMustBeAfterStartTime(WidgetRef ref) => ref.t(
    'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น',
    'End time must be after start time',
  );

  static String pleaseProvideReason(WidgetRef ref) =>
      ref.t('กรุณาระบุเหตุผลในการลา', 'Please provide a reason for leave');

  static String rejectLeaveRequest(WidgetRef ref) =>
      ref.t('ปฏิเสธคำขอลา', 'Reject Leave Request');

  static String pleaseProvideRejectionReason(WidgetRef ref) =>
      ref.t('กรุณาระบุเหตุผลในการปฏิเสธคำขอลานี้', 'Please provide a reason for rejecting this leave request.');

  static String rejectionReason(WidgetRef ref) =>
      ref.t('เหตุผลในการปฏิเสธ', 'Rejection Reason');

  static String enterRejectionReason(WidgetRef ref) =>
      ref.t('กรอกเหตุผลในการปฏิเสธ', 'Enter reason for rejection');

  static String rejectionReasonRequired(WidgetRef ref) =>
      ref.t('กรุณาระบุเหตุผลในการปฏิเสธ', 'Rejection reason is required');

  static String requestType(WidgetRef ref) =>
      ref.t('ประเภทคำขอ', 'Request Type');

  static String pleaseSelectDateFirstForShift(WidgetRef ref) =>
      ref.t('กรุณาเลือกวันที่ก่อนเพื่อโหลดกะการทำงานของคุณ', 'Please select a date first to load your working shift');

  static String employeeNotFound(WidgetRef ref) =>
      ref.t('ไม่พบข้อมูลพนักงาน', 'Employee not found');

  static String errorSubmittingRequest(WidgetRef ref) =>
      ref.t('เกิดข้อผิดพลาดในการส่งคำขอลา', 'Error submitting leave request');

  
  static String fromDate(WidgetRef ref) => ref.t('จาก:', 'From:');

  static String toDate(WidgetRef ref) => ref.t('ถึง:', 'To:');

  static String totalDaysLabel(WidgetRef ref) =>
      ref.t('จำนวนวันทั้งหมด:', 'Total Days:');

  static String attachmentsLabel(WidgetRef ref) =>
      ref.t('เอกสารแนบ', 'Attachments');

  static String createdLabel(WidgetRef ref) => ref.t('สร้างเมื่อ:', 'Created:');

  static String dayUnit(WidgetRef ref) => ref.t('วัน', 'day');

  static String daysUnit(WidgetRef ref) => ref.t('วัน', 'days');


  static String leaveRequestTitle(WidgetRef ref) =>
      ref.t('คำขอลา', 'Leave Request');

  static String cameraPermissionRequired(WidgetRef ref) =>
      ref.t('ต้องการสิทธิ์ในการเข้าถึงกล้อง', 'Camera permission is required');

  static String cameraPermissionDenied(WidgetRef ref) =>
      ref.t('สิทธิ์ในการเข้าถึงกล้องถูกปฏิเสธ กรุณาเปิดในตั้งค่า', 'Camera permission denied. Please enable in settings');

  static String galleryPermissionRequired(WidgetRef ref) =>
      ref.t('ต้องการสิทธิ์ในการเข้าถึงแกลเลอรี', 'Gallery permission is required');

  static String galleryPermissionDenied(WidgetRef ref) =>
      ref.t('สิทธิ์ในการเข้าถึงแกลเลอรีถูกปฏิเสธ กรุณาเปิดในตั้งค่า', 'Gallery permission denied. Please enable in settings');

  static String errorUploadingImage(WidgetRef ref) =>
      ref.t('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ', 'Error uploading image');

  static String durationType(WidgetRef ref) =>
      ref.t('ประเภทระยะเวลา', 'Duration Type');

  static String daily(WidgetRef ref) => ref.t('รายวัน', 'Daily');

  static String hourly(WidgetRef ref) => ref.t('รายชั่วโมง', 'Hourly');

  static String workingShift(WidgetRef ref) =>
      ref.t('กะการทำงาน', 'Working Shift');

  static String leavePeriod(WidgetRef ref) =>
      ref.t('ระยะเวลาลา', 'Leave Period');

  static String leaveDate(WidgetRef ref) => ref.t('วันที่ลา', 'Leave Date');

  static String fromDateField(WidgetRef ref) =>
      ref.t('วันที่เริ่มต้น', 'From Date');

  static String toDateField(WidgetRef ref) => ref.t('วันที่สิ้นสุด', 'To Date');

  static String date(WidgetRef ref) => ref.t('วันที่', 'Date');

  static String timePeriod(WidgetRef ref) => ref.t('ช่วงเวลา', 'Time Period');

  static String startTime(WidgetRef ref) => ref.t('เวลาเริ่มต้น', 'Start Time');

  static String endTime(WidgetRef ref) => ref.t('เวลาสิ้นสุด', 'End Time');

  static String selectTime(WidgetRef ref) => ref.t('เลือกเวลา', 'Select time');

  static String selectDate(WidgetRef ref) =>
      ref.t('เลือกวันที่', 'Select date');

  static String reasonField(WidgetRef ref) => ref.t('เหตุผล', 'Reason');

  static String reasonHint(WidgetRef ref) => ref.t(
    'กรุณาระบุเหตุผลในการขอลาของคุณ...',
    'Please provide a reason for your leave request...',
  );

  static String supportingImage(WidgetRef ref) =>
      ref.t('รูปภาพประกอบ (ไม่บังคับ)', 'Supporting Image (Optional)');

  static String takePhoto(WidgetRef ref) => ref.t('ถ่ายรูป', 'Take Photo');

  static String gallery(WidgetRef ref) => ref.t('แกลเลอรี่', 'Gallery');

  static String submitLeaveRequest(WidgetRef ref) =>
      ref.t('ส่งคำขอลา', 'Submit Leave Request');

  static String fillAllRequiredFields(WidgetRef ref) =>
      ref.t('กรุณากรอกข้อมูลที่จำเป็นทั้งหมด', 'Fill all required fields');

  static String unknownEmployee(WidgetRef ref) =>
      ref.t('พนักงานไม่ทราบชื่อ', 'Unknown Employee');

  static String failedToSubmitRequest(WidgetRef ref) =>
      ref.t('ไม่สามารถส่งคำขอลาได้', 'Failed to submit leave request');

  
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

    
    return typeName;
  }

  
  static String translateStatus(WidgetRef ref, String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.contains('approved')) {
      return approved(ref);
    } else if (statusLower.contains('rejected')) {
      return rejected(ref);
    } else if (statusLower.contains('pending')) {
      return pending(ref);
    }

    
    return status;
  }

  // Approval Steps Translations
  static String approveByStep(WidgetRef ref) =>
      ref.t('อนุมัติตามขั้นตอน', 'Approve By Step');

  static String teamLead(WidgetRef ref) =>
      ref.t('หัวหน้าทีม', 'Team Lead');

  static String hr(WidgetRef ref) =>
      ref.t('ฝ่ายบุคคล', 'HR');

  static String approver(WidgetRef ref) =>
      ref.t('ผู้อนุมัติ', 'Approver');

  static String manager(WidgetRef ref) =>
      ref.t('ผู้จัดการ', 'Manager');

  static String warehouseManager(WidgetRef ref) =>
      ref.t('ผู้จัดการคลังสินค้า', 'Warehouse Manager');

  static String warehouseWorker(WidgetRef ref) =>
      ref.t('พนักงานคลังสินค้า', 'Warehouse Worker');

  static String warehouseAdministrator(WidgetRef ref) =>
      ref.t('ผู้ดูแลคลังสินค้า', 'Warehouse Administrator');

  static String approvedStatus(WidgetRef ref) =>
      ref.t('อนุมัติแล้ว', 'Approved');

  static String pendingStatus(WidgetRef ref) =>
      ref.t('รอดำเนินการ', 'Pending');
}
