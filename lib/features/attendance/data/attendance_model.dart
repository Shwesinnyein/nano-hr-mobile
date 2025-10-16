import 'package:intl/intl.dart';

class Attendance {
  Attendance({
    required this.id,
    required this.uid,
    required this.employeeId,
    required this.location,
    required this.company,
    required this.branch,
    required this.type,
    required this.date,
    required this.time,
    required this.checkInAt,
    this.checkOutAt,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.isAutoCheckout,
    this.employeeName,
    this.duration,
    this.status,
  });

  final String id;
  final String uid;
  final String employeeId;
  final String location;
  final String company;
  final String branch;
  final String type;
  final String date;
  final String time;
  final DateTime checkInAt;
  DateTime? checkOutAt;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAutoCheckout;
  final String? employeeName;
  final String? duration;
  final String? status;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      try {
        DateTime parsedDate;
        if (dateValue is String) {
          parsedDate = DateTime.parse(dateValue);
        } else if (dateValue is int) {
          // Handle Unix timestamp (seconds)
          parsedDate = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        } else if (dateValue is double) {
          // Handle Unix timestamp (seconds with decimals)
          parsedDate = DateTime.fromMillisecondsSinceEpoch(
            (dateValue * 1000).round(),
          );
        } else {
          return DateTime.now();
        }

        // Convert to local time if it's in UTC
        if (parsedDate.isUtc) {
          parsedDate = parsedDate.toLocal();
        }

        return parsedDate;
      } catch (e) {
        return DateTime.now();
      }
    }

    // Parse time-only strings (HH:mm:ss format) by combining with date
    DateTime parseTimeWithDate(String timeString, String dateString) {
      try {
        final date = DateTime.parse(dateString);
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

          return DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
            second,
          );
        }
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    // Parse all the real API fields
    final id = json['id']?.toString() ?? '';
    final uid = json['uid']?.toString() ?? '';
    final employeeId = json['employeeId']?.toString() ?? '';
    final location = json['location']?.toString() ?? 'Office';
    final company = json['company']?.toString() ?? 'NANO-STORES';
    final branch = json['branch']?.toString() ?? 'Office';
    final type = json['type']?.toString() ?? 'checkin';
    final date =
        json['date']?.toString() ??
        DateTime.now().toIso8601String().split('T')[0];
    final time =
        json['time']?.toString() ??
        DateTime.now().toIso8601String().split('T')[1].split('.')[0];

    // Parse timestamps
    final timestamp = parseDate(json['timestamp']);
    final createdAt = parseDate(json['createdAt']);
    final updatedAt = parseDate(json['updatedAt']);

    // Parse check-in and check-out times
    DateTime? checkInAt;
    DateTime? checkOutAt;

    if (json['checkInAt'] != null) {
      final checkInTime = json['checkInAt'].toString();
      // Check if it's a time-only string (HH:mm:ss format)
      if (checkInTime.contains(':') &&
          !checkInTime.contains('T') &&
          !checkInTime.contains('-')) {
        checkInAt = parseTimeWithDate(checkInTime, date);
      } else {
        checkInAt = parseDate(json['checkInAt']);
      }
    }

    if (json['checkOutAt'] != null) {
      final checkOutTime = json['checkOutAt'].toString();
      // Check if it's a time-only string (HH:mm:ss format)
      if (checkOutTime.contains(':') &&
          !checkOutTime.contains('T') &&
          !checkOutTime.contains('-')) {
        checkOutAt = parseTimeWithDate(checkOutTime, date);
      } else {
        checkOutAt = parseDate(json['checkOutAt']);
      }
    }

    // Ensure we have a valid checkInAt
    final finalCheckInAt = checkInAt ?? timestamp;

    // Parse boolean fields
    final isAutoCheckout =
        json['isAutoCheckout'] == true || json['isAutoCheckout'] == 'true';

    // Create attendance record
    return Attendance(
      id: id,
      uid: uid,
      employeeId: employeeId,
      location: location,
      company: company,
      branch: branch,
      type: type,
      date: date,
      time: time,
      checkInAt: finalCheckInAt,
      checkOutAt: checkOutAt,
      timestamp: timestamp,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAutoCheckout: isAutoCheckout,
      employeeName: json['employeeName']?.toString(),
      duration: json['duration']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'employeeId': employeeId,
      'location': location,
      'company': company,
      'branch': branch,
      'type': type,
      'date': date,
      'time': time,
      'checkInAt': checkInAt.toIso8601String(),
      'checkOutAt': checkOutAt?.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAutoCheckout': isAutoCheckout,
      'employeeName': employeeName,
      'duration': duration,
      'status': status,
    };
  }

  // Helper method to format check-in time
  String get formattedCheckInTime {
    return DateFormat('HH:mm:ss').format(checkInAt);
  }

  // Helper method to format check-out time
  String? get formattedCheckOutTime {
    if (checkOutAt == null) return null;
    return DateFormat('HH:mm:ss').format(checkOutAt!);
  }

  // Helper method to get duration if both check-in and check-out exist
  String? get formattedDuration {
    if (checkOutAt == null) return null;
    final duration = checkOutAt!.difference(checkInAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Helper method to check if this is a check-in record
  bool get isCheckIn {
    return checkOutAt == null;
  }

  // Helper method to check if this is a check-out record
  bool get isCheckOut {
    return checkOutAt != null;
  }

  // Helper method to get the status text
  String get statusText {
    if (isCheckIn) {
      return 'Checked In';
    } else {
      return 'Checked Out';
    }
  }
}
