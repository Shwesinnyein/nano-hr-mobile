class LeaveSetting {
  final String id;
  final String uid;
  final String leaveType;
  final String leaveTypeName;
  final String leaveTypeNameEng;
  final String maxDays;
  final String gender;
  final String description;
  final String createdAt;
  final String updatedAt;

  LeaveSetting({
    required this.id,
    required this.uid,
    required this.leaveType,
    required this.leaveTypeName,
    required this.leaveTypeNameEng,
    required this.maxDays,
    required this.gender,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveSetting.fromJson(Map<String, dynamic> json) {
    return LeaveSetting(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      leaveType: json['leaveType'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      leaveTypeNameEng:
          json['leaveTypeNameEng'] ?? json['leaveTypeEng'] ?? '',
      maxDays: json['maxDays'] ?? '0',
      gender: json['gender'] ?? 'All',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'leaveType': leaveType,
      'leaveTypeName': leaveTypeName,
      'leaveTypeNameEng': leaveTypeNameEng,
      'maxDays': maxDays,
      'gender': gender,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }


  int get maxDaysInt => int.tryParse(maxDays) ?? 0;
  bool get isAvailableForAll => gender == 'All';
  String get displayName =>
      leaveTypeNameEng.isNotEmpty ? leaveTypeNameEng : leaveType;
}

class LeaveSettingsResponse {
  final bool success;
  final String message;
  final int count;
  final List<LeaveSetting> data;
  final bool employeeEligible;
  final int monthsWithCompany;
  final int requiredMonths;
  final String employeeGender;

  LeaveSettingsResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
    required this.employeeEligible,
    required this.monthsWithCompany,
    required this.requiredMonths,
    required this.employeeGender,
  });

  factory LeaveSettingsResponse.fromJson(Map<String, dynamic> json) {
    return LeaveSettingsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (item) => LeaveSetting.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      employeeEligible: json['employeeEligibleForAnnualLeave'] ?? json['employeeEligible'] ?? false,
      monthsWithCompany: json['monthsWithCompany'] ?? 0,
      requiredMonths: json['requiredMonths'] ?? 0,
      employeeGender: json['employeeGender'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'count': count,
      'data': data.map((item) => item.toJson()).toList(),
      'employeeEligible': employeeEligible,
      'monthsWithCompany': monthsWithCompany,
      'requiredMonths': requiredMonths,
      'employeeGender': employeeGender,
    };
  }
}

class LeaveBalance {
  final String employeeId;
  final String employeeName;
  final int year;
  final bool eligible;
  final int monthsWithCompany;
  final int? requiredMonths;
  final int? hoursPerDay;
  final List<LeaveTypeBalance> balances;
  final LeaveSummary summary;

  LeaveBalance({
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.eligible,
    required this.monthsWithCompany,
    this.requiredMonths,
    this.hoursPerDay,
    required this.balances,
    required this.summary,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      eligible: json['eligibleForAnnualLeave'] ?? json['eligible'] ?? true,
      monthsWithCompany: json['monthsWithCompany'] ?? 0,
      requiredMonths: json['requiredMonths'] as int?,
      hoursPerDay: json['hoursPerDay'] as int?,
      balances:
          (json['balances'] as List<dynamic>?)
              ?.map((balance) => LeaveTypeBalance.fromJson(balance))
              .toList() ??
          [],
      summary: LeaveSummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'year': year,
      'eligibleForAnnualLeave': eligible,
      'eligible': eligible,
      'monthsWithCompany': monthsWithCompany,
      'requiredMonths': requiredMonths,
      'hoursPerDay': hoursPerDay,
      'balances': balances.map((balance) => balance.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }

  
  LeaveTypeBalance? getLeaveTypeByName(String name) {
    return balances.firstWhere(
      (balance) =>
          balance.leaveTypeName.toLowerCase().contains(name.toLowerCase()),
      orElse: () => LeaveTypeBalance.empty(),
    );
  }

  
  double get annualLeave =>
      getLeaveTypeByName('Annual')?.remaining ?? 0.0;
  double get sickLeave =>
      getLeaveTypeByName('ป่วย')?.remaining ?? 0.0;
  double get personalLeave =>
      getLeaveTypeByName('ลา (โดยไม่ได้รับค่าจ้าง)')?.remaining ?? 0.0;
  double get vacationLeave => annualLeave;
  double get leaveWithoutPay => personalLeave;
  double get maternityLeave => 0.0;
  double get leaveOfAbsencePaid =>
      getLeaveTypeByName('ลากิจ(ได้รับค่าจ้าง)')?.remaining ?? 0.0;
  double get emergency => 0.0;
}

class LeaveTypeBalance {
  final String leaveTypeId;
  final String leaveTypeName;
  final String? leaveTypeNameEng;
  final int totalAllocated;
  final double used;
  final double remaining;
  final double? remainingHours;
  final String? remainingDaysHours;
  final String? description;
  final bool isPaid;
  final bool isActive;
  final int percentageUsed;

  LeaveTypeBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    this.leaveTypeNameEng,
    required this.totalAllocated,
    required this.used,
    required this.remaining,
    this.remainingHours,
    this.remainingDaysHours,
    this.description,
    required this.isPaid,
    required this.isActive,
    required this.percentageUsed,
  });

  factory LeaveTypeBalance.fromJson(Map<String, dynamic> json) {
    return LeaveTypeBalance(
      leaveTypeId: json['leaveTypeId'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      leaveTypeNameEng:
          json['leaveTypeNameEng'] ?? json['leaveTypeEng'],
      totalAllocated:
          int.tryParse(json['totalAllocated']?.toString() ?? '0') ?? 0,
      used: (json['used'] is int)
          ? (json['used'] as int).toDouble()
          : (json['used'] as double? ?? 0.0),
      remaining: (json['remaining'] is int)
          ? (json['remaining'] as int).toDouble()
          : (json['remaining'] as double? ?? 0.0),
      remainingHours: (json['remainingHours'] is int)
          ? (json['remainingHours'] as int).toDouble()
          : (json['remainingHours'] as double?),
      remainingDaysHours: json['remainingDaysHours']?.toString(),
      description: json['description']?.toString(),
      isPaid: json['isPaid'] ?? false,
      isActive: json['isActive'] ?? true,
      percentageUsed: json['percentageUsed'] ?? 0,
    );
  }

  factory LeaveTypeBalance.empty() {
    return LeaveTypeBalance(
      leaveTypeId: '',
      leaveTypeName: '',
      leaveTypeNameEng: null,
      totalAllocated: 0,
      used: 0.0,
      remaining: 0.0,
      remainingHours: 0.0,
      remainingDaysHours: null,
      description: null,
      isPaid: false,
      isActive: false,
      percentageUsed: 0,
    );
  }

  
  String getLocalizedName(bool isThai) {
    if (!isThai && leaveTypeNameEng != null && leaveTypeNameEng!.isNotEmpty) {
      return leaveTypeNameEng!;
    }
    return leaveTypeName;
  }

  Map<String, dynamic> toJson() {
    return {
      'leaveTypeId': leaveTypeId,
      'leaveTypeName': leaveTypeName,
      'leaveTypeNameEng': leaveTypeNameEng,
      'totalAllocated': totalAllocated,
      'used': used,
      'remaining': remaining,
      'remainingHours': remainingHours,
      'remainingDaysHours': remainingDaysHours,
      'isPaid': isPaid,
      'isActive': isActive,
      'percentageUsed': percentageUsed,
    };
  }
}

class LeaveSummary {
  final int totalLeaveTypes;
  final int totalDaysAllocated;
  final double totalDaysUsed;
  final double totalDaysRemaining;
  final int? totalRemainingHours;

  LeaveSummary({
    required this.totalLeaveTypes,
    required this.totalDaysAllocated,
    required this.totalDaysUsed,
    required this.totalDaysRemaining,
    this.totalRemainingHours,
  });

  factory LeaveSummary.fromJson(Map<String, dynamic> json) {
    return LeaveSummary(
      totalLeaveTypes: json['totalLeaveTypes'] ?? 0,
      totalDaysAllocated:
          int.tryParse(json['totalDaysAllocated']?.toString() ?? '0') ?? 0,
      totalDaysUsed: (json['totalDaysUsed'] is int)
          ? (json['totalDaysUsed'] as int).toDouble()
          : (json['totalDaysUsed'] as double? ?? 0.0),
      totalDaysRemaining: (json['totalDaysRemaining'] is int)
          ? (json['totalDaysRemaining'] as int).toDouble()
          : (json['totalDaysRemaining'] as double? ?? 0.0),
      totalRemainingHours: json['totalRemainingHours'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLeaveTypes': totalLeaveTypes,
      'totalDaysAllocated': totalDaysAllocated,
      'totalDaysUsed': totalDaysUsed,
      'totalDaysRemaining': totalDaysRemaining,
      'totalRemainingHours': totalRemainingHours,
    };
  }
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
  final double? totalDays;
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
    this.totalDays,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName:
          json['employeeName'] ?? 'Employee', 
      leaveType:
          json['leaveTypeName'] ??
          json['leaveType'] ??
          '', 
      startDate:
          json['startDate'] ?? json['fromDate'], 
      endDate: json['endDate'] ?? json['toDate'], 
      date: json['date'],
      workingShift: json['workingShift'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      totalDays: json['totalDays'] != null
          ? (json['totalDays'] is int
              ? (json['totalDays'] as int).toDouble()
              : json['totalDays'] as double?)
          : null,
      attachments: _parseAttachments(json),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  static List<Map<String, dynamic>> _parseAttachments(
    Map<String, dynamic> json,
  ) {
    try {
      
      final attachment = json['attachment'];

      if (attachment == null) {
        return [];
      }

      
      if (attachment is Map<String, dynamic>) {
        final files = attachment['files'] as List<dynamic>?;
        if (files != null) {
          return files.map((file) {
            if (file is Map<String, dynamic>) {
              return Map<String, dynamic>.from(file);
            } else {
              return {'url': file.toString(), 'type': 'file'};
            }
          }).toList();
        }

        
        return [Map<String, dynamic>.from(attachment)];
      }

      
      if (attachment is String) {
        return [
          {'url': attachment, 'type': 'file'},
        ];
      }

      
      if (attachment is List) {
        return attachment.map((item) {
          if (item is Map<String, dynamic>) {
            return Map<String, dynamic>.from(item);
          } else {
            return {'url': item.toString(), 'type': 'file'};
          }
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
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

  
  String get type => leaveType;
  DateTime? get start =>
      startDate != null ? DateTime.tryParse(startDate!) : null;
  DateTime? get end => endDate != null ? DateTime.tryParse(endDate!) : null;

  String? get requestType =>
      startTime != null && endTime != null ? 'hourly' : 'daily';
  String? get leaveTypeName => leaveType;
  String get statusName => status;
  String? get fromDate => startDate;
  String? get toDate => endDate;
  int? get calculatedTotalDays =>
      start != null && end != null ? end!.difference(start!).inDays + 1 : null;
  String? get attachmentUrl =>
      attachments.isNotEmpty ? attachments.first['url'] : null;
}
