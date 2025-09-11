class LeaveBalance {
  final int annualLeave;
  final int sickLeave;
  final int personalLeave;
  final int usedAnnualLeave;
  final int usedSickLeave;
  final int usedPersonalLeave;

  LeaveBalance({
    required this.annualLeave,
    required this.sickLeave,
    required this.personalLeave,
    required this.usedAnnualLeave,
    required this.usedSickLeave,
    required this.usedPersonalLeave,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      annualLeave: json['annualLeave'] ?? 0,
      sickLeave: json['sickLeave'] ?? 0,
      personalLeave: json['personalLeave'] ?? 0,
      usedAnnualLeave: json['usedAnnualLeave'] ?? 0,
      usedSickLeave: json['usedSickLeave'] ?? 0,
      usedPersonalLeave: json['usedPersonalLeave'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annualLeave': annualLeave,
      'sickLeave': sickLeave,
      'personalLeave': personalLeave,
      'usedAnnualLeave': usedAnnualLeave,
      'usedSickLeave': usedSickLeave,
      'usedPersonalLeave': usedPersonalLeave,
    };
  }

  // Additional properties for UI compatibility
  double get vacationLeave => annualLeave.toDouble();
  double get leaveWithoutPay => personalLeave.toDouble();
  double get maternityLeave => 0.0;
  double get leaveOfAbsencePaid => 0.0;
  double get emergency => 0.0;
}

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final String? startDate;
  final String? endDate;
  final String? date;
  final String? workingShift;
  final String? startTime;
  final String? endTime;
  final String reason;
  final String status;
  final List<Map<String, dynamic>> attachments;
  final String createdAt;
  final String updatedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    this.startDate,
    this.endDate,
    this.date,
    this.workingShift,
    this.startTime,
    this.endTime,
    required this.reason,
    required this.status,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      leaveType: json['leaveType'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
      date: json['date'],
      workingShift: json['workingShift'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      attachments: List<Map<String, dynamic>>.from(json['attachments'] ?? []),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'date': date,
      'workingShift': workingShift,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'status': status,
      'attachments': attachments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper getters for UI
  String get type => leaveType;
  DateTime? get start =>
      startDate != null ? DateTime.tryParse(startDate!) : null;
  DateTime? get end => endDate != null ? DateTime.tryParse(endDate!) : null;

  // Additional properties for UI compatibility
  String? get requestType =>
      startTime != null && endTime != null ? 'hourly' : 'daily';
  String? get leaveTypeName => leaveType;
  String get statusName => status;
  String? get fromDate => startDate;
  String? get toDate => endDate;
  int? get totalDays =>
      start != null && end != null ? end!.difference(start!).inDays + 1 : null;
  String? get attachmentUrl =>
      attachments.isNotEmpty ? attachments.first['url'] : null;
}
