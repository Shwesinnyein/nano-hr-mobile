import '../../../core/utils/date_utils.dart';

/// Refactored attendance model with improved JSON parsing and validation
class Attendance {
  final String id;
  final String uid;
  final String employeeId;
  final String employeeName;
  final String location;
  final String company;
  final String branch;
  final String branchName;
  final String type;
  final String date;
  final String time;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String timestamp;
  final String createdAt;
  final String updatedAt;
  final bool isAutoCheckout;

  const Attendance({
    required this.id,
    required this.uid,
    required this.employeeId,
    required this.employeeName,
    required this.location,
    required this.company,
    required this.branch,
    required this.branchName,
    required this.type,
    required this.date,
    required this.time,
    this.checkInAt,
    this.checkOutAt,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.isAutoCheckout,
  });

  /// Factory constructor with robust JSON parsing
  factory Attendance.fromJson(Map<String, dynamic> json) {
    try {
      return Attendance(
        id: _parseString(json['id']),
        uid: _parseString(json['uid']),
        employeeId: _parseString(json['employeeId']),
        employeeName: _parseString(json['employeeName']),
        location: _parseString(json['location']),
        company: _parseString(json['company']),
        branch: _parseString(json['branch']),
        branchName: _parseString(json['branchName']),
        type: _parseString(json['type']),
        date: _parseString(json['date']),
        time: _parseString(json['time']),
        checkInAt: _parseDateTime(json['checkInAt'], json['date']),
        checkOutAt: _parseDateTime(json['checkOutAt'], json['date']),
        timestamp: _parseString(json['timestamp']),
        createdAt: _parseString(json['createdAt']),
        updatedAt: _parseString(json['updatedAt']),
        isAutoCheckout: _parseBool(json['isAutoCheckout']),
      );
    } catch (e) {
      throw FormatException('Failed to parse Attendance from JSON: $e');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'location': location,
      'company': company,
      'branch': branch,
      'branchName': branchName,
      'type': type,
      'date': date,
      'time': time,
      'checkInAt': checkInAt?.toIso8601String(),
      'checkOutAt': checkOutAt?.toIso8601String(),
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isAutoCheckout': isAutoCheckout,
    };
  }

  /// Create a copy with updated fields
  Attendance copyWith({
    String? id,
    String? uid,
    String? employeeId,
    String? employeeName,
    String? location,
    String? company,
    String? branch,
    String? branchName,
    String? type,
    String? date,
    String? time,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? timestamp,
    String? createdAt,
    String? updatedAt,
    bool? isAutoCheckout,
  }) {
    return Attendance(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      location: location ?? this.location,
      company: company ?? this.company,
      branch: branch ?? this.branch,
      branchName: branchName ?? this.branchName,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAutoCheckout: isAutoCheckout ?? this.isAutoCheckout,
    );
  }

  /// Check if this is a check-in record
  bool get isCheckIn => type == 'checkin' || type == 'checked_in';

  /// Check if this is a check-out record
  bool get isCheckOut => type == 'checkout' || type == 'checked_out';

  /// Check if employee has checked out today
  bool get hasCheckedOut => checkOutAt != null;

  /// Get duration between check-in and check-out
  Duration? get workDuration {
    if (checkInAt == null || checkOutAt == null) return null;
    return checkOutAt!.difference(checkInAt!);
  }

  /// Format work duration as string
  String get formattedWorkDuration {
    final duration = workDuration;
    if (duration == null) return 'N/A';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  String toString() {
    return 'Attendance(id: $id, employeeId: $employeeId, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Private helper methods for JSON parsing

  /// Parse string with null safety
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Parse boolean with null safety
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  /// Parse DateTime with support for time-only strings
  static DateTime? _parseDateTime(dynamic value, String? dateString) {
    if (value == null) return null;
    
    try {
      final stringValue = value.toString();
      
      // Check if it's a time-only string (HH:mm:ss format)
      if (stringValue.contains(':') && 
          !stringValue.contains('T') && 
          !stringValue.contains('-') &&
          dateString != null) {
        return AppDateUtils.parseTimeWithDate(stringValue, dateString);
      }
      
      // Try to parse as full DateTime
      return DateTime.parse(stringValue);
    } catch (e) {
      // Return current time as fallback
      return AppDateUtils.getThailandTime();
    }
  }
}
