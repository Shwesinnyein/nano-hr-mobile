import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/services/leave_service.dart';

class LeaveBalance {
  LeaveBalance({
    required this.vacationLeave,
    required this.sickLeave,
    required this.leaveWithoutPay,
    required this.maternityLeave,
    required this.leaveOfAbsencePaid,
    required this.emergency,
    required this.study,
    required this.compensatory,
  });
  double vacationLeave;
  double sickLeave;
  double leaveWithoutPay;
  double maternityLeave;
  double leaveOfAbsencePaid;
  double emergency;
  double study;
  double compensatory;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      vacationLeave: (json['vacationLeave'] ?? json['annual'] ?? 0).toDouble(),
      sickLeave: (json['sickLeave'] ?? json['sick'] ?? 0).toDouble(),
      leaveWithoutPay: (json['leaveWithoutPay'] ?? json['casual'] ?? 0)
          .toDouble(),
      maternityLeave: (json['maternityLeave'] ?? json['maternity'] ?? 0)
          .toDouble(),
      leaveOfAbsencePaid: (json['leaveOfAbsencePaid'] ?? json['paternity'] ?? 0)
          .toDouble(),
      emergency: (json['emergency'] ?? 0).toDouble(),
      study: (json['study'] ?? 0).toDouble(),
      compensatory: (json['compensatory'] ?? 0).toDouble(),
    );
  }
}

class LeaveTypeData {
  final String type;
  final String name;
  final String icon;
  final int quota;
  final int remaining;
  final int color;

  LeaveTypeData({
    required this.type,
    required this.name,
    required this.icon,
    required this.quota,
    required this.remaining,
    required this.color,
  });

  factory LeaveTypeData.fromJson(Map<String, dynamic> json) {
    return LeaveTypeData(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      quota: json['quota'] ?? 0,
      remaining: json['remaining'] ?? 0,
      color: json['color'] ?? 0xFF000000,
    );
  }
}

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'pending',
    this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.durationType = 'daily',
    this.attachmentUrl,
    // New fields from backend API
    this.uid,
    this.employeeId,
    this.leaveTypeName,
    this.requestType,
    this.totalDays,
    this.createdAt,
    this.updatedAt,
    this.statusName,
    // Hourly leave fields
    this.date,
    this.workingShift,
    this.startTime,
    this.endTime,
  });

  final String id;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  String status;
  final DateTime? submittedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String durationType;
  final String? attachmentUrl;

  // New fields from backend API
  final String? uid;
  final String? employeeId;
  final String? leaveTypeName;
  final String? requestType;
  final int? totalDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? statusName;

  // Hourly leave fields
  final DateTime? date;
  final String? workingShift;
  final String? startTime;
  final String? endTime;

  // Legacy properties for backward compatibility
  String get userId => 'current_user'; // This should come from auth
  DateTime get start => fromDate;
  DateTime get end => toDate;
  String get type => leaveType;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    // Handle date parsing for different formats
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Handle both ISO8601 and YYYY-MM-DD formats
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        } else {
          return DateTime.parse(dateStr + 'T00:00:00.000Z');
        }
      } catch (e) {
        return null;
      }
    }

    return LeaveRequest(
      id: json['id'] ?? '',
      leaveType: json['leaveType'] ?? json['type'] ?? '',
      fromDate:
          parseDate(json['fromDate'] ?? json['startDate'] ?? json['start']) ??
          DateTime.now().subtract(const Duration(days: 1)),
      toDate:
          parseDate(json['toDate'] ?? json['endDate'] ?? json['end']) ??
          DateTime.now(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectedBy: json['rejectedBy'],
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      durationType: json['durationType'] ?? json['requestType'] ?? 'daily',
      attachmentUrl: json['attachment'] ?? json['attachmentUrl'],

      // New fields from backend API
      uid: json['uid'],
      employeeId: json['employeeId'],
      leaveTypeName: json['leaveTypeName'],
      requestType: json['requestType'],
      totalDays: json['totalDays'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      statusName: json['statusName'],

      // Hourly leave fields
      date: parseDate(json['date']),
      workingShift: json['workingShift'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveType': leaveType,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'durationType': durationType,
      'attachmentUrl': attachmentUrl,

      // New fields from backend API
      'uid': uid,
      'employeeId': employeeId,
      'leaveTypeName': leaveTypeName,
      'requestType': requestType,
      'totalDays': totalDays,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'statusName': statusName,

      // Hourly leave fields
      'date': date?.toIso8601String(),
      'workingShift': workingShift,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class LeaveRepository {
  final LeaveService _leaveService;

  LeaveRepository(this._leaveService);

  Future<LeaveBalance> getBalance(String userId) async {
    return await _leaveService.getLeaveBalance();
  }

  Future<List<LeaveRequest>> listRequests(String userId) async {
    return await _leaveService.getLeaveRequests();
  }

  Future<LeaveRequest> submitRequest(LeaveRequest r) async {
    return await _leaveService.submitLeaveRequest(r);
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final leaveService = ref.watch(leaveServiceProvider);
  return LeaveRepository(leaveService);
});

class LeaveVm {
  LeaveVm(this.balance, this.requests);
  final LeaveBalance balance;
  final List<LeaveRequest> requests;
}

class LeaveController extends StateNotifier<AsyncValue<LeaveVm>> {
  LeaveController(this._repo, this._userId)
    : super(const AsyncValue.loading()) {
    load();
  }
  final LeaveRepository _repo;
  final String _userId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final bal = await _repo.getBalance(_userId);
      final reqs = await _repo.listRequests(_userId);
      state = AsyncValue.data(LeaveVm(bal, reqs));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submit(String type, DateTimeRange range, String reason) async {
    await _repo.submitRequest(
      LeaveRequest(
        id: '',
        leaveType: type,
        fromDate: range.start,
        toDate: range.end,
        reason: reason,
      ),
    );
    await load();
  }
}

final leaveControllerProvider =
    StateNotifierProvider.family<LeaveController, AsyncValue<LeaveVm>, String>((
      ref,
      userId,
    ) {
      final repo = ref.watch(leaveRepositoryProvider);
      return LeaveController(repo, userId);
    });
