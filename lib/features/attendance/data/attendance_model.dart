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
    this.checkInDate,
    this.checkOutDate,
    this.isOvernightShift = false,
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
  final String? checkInDate; // Date when checked in (YYYY-MM-DD)
  final String? checkOutDate; // Date when checked out (YYYY-MM-DD)
  final bool isOvernightShift; // true if checkInDate != checkOutDate

  factory Attendance.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      try {
        DateTime parsedDate;
        if (dateValue is String) {
          parsedDate = DateTime.parse(dateValue);
        } else if (dateValue is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        } else if (dateValue is double) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(
            (dateValue * 1000).round(),
          );
        } else {
          return DateTime.now();
        }

        if (parsedDate.isUtc) {
          parsedDate = parsedDate.toLocal();
        }

        return parsedDate;
      } catch (e) {
        return DateTime.now();
      }
    }

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

    final id = json['id']?.toString() ?? '';
    final uid = json['uid']?.toString() ?? '';
    final employeeId = json['employeeId']?.toString() ?? '';
    final location = json['checkInLocation']?.toString() ?? json['location']?.toString() ?? 'Office';
    final company = json['company']?.toString() ?? 'NANO-STORES';
    final branch = json['branch']?.toString() ?? 'Office';
    final type = json['type']?.toString() ?? 'checkin';
    final date =
        json['date']?.toString() ??
        DateTime.now().toIso8601String().split('T')[0];
    final time =
        json['time']?.toString() ??
        DateTime.now().toIso8601String().split('T')[1].split('.')[0];

    final timestamp = parseDate(json['timestamp']);
    final createdAt = parseDate(json['createdAt']);
    final updatedAt = parseDate(json['updatedAt']);

    DateTime? checkInAt;
    DateTime? checkOutAt;

    if (json['checkInAt'] != null) {
      final checkInTime = json['checkInAt'].toString();
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
      if (checkOutTime.contains(':') &&
          !checkOutTime.contains('T') &&
          !checkOutTime.contains('-')) {
        checkOutAt = parseTimeWithDate(checkOutTime, date);
      } else {
        checkOutAt = parseDate(json['checkOutAt']);
      }
    }

    final finalCheckInAt = checkInAt ?? timestamp;

    final isAutoCheckout =
        json['isAutoCheckout'] == true || json['isAutoCheckout'] == 'true';
    
    // Parse checkInDate and checkOutDate
    final checkInDate = json['checkInDate']?.toString();
    final checkOutDate = json['checkOutDate']?.toString();
    
    // Determine if it's an overnight shift
    final isOvernightShift = json['isOvernightShift'] == true || 
        json['isOvernightShift'] == 'true' ||
        (checkInDate != null && checkOutDate != null && checkInDate != checkOutDate);

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
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      isOvernightShift: isOvernightShift,
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
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'isOvernightShift': isOvernightShift,
    };
  }

  String get formattedCheckInTime {
    return DateFormat('HH:mm:ss').format(checkInAt);
  }

  String? get formattedCheckOutTime {
    if (checkOutAt == null) return null;
    return DateFormat('HH:mm:ss').format(checkOutAt!);
  }

  String? get formattedDuration {
    if (checkOutAt == null) return null;
    final duration = checkOutAt!.difference(checkInAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  bool get isCheckIn {
    return checkOutAt == null;
  }

  bool get isCheckOut {
    return checkOutAt != null;
  }

  String get statusText {
    if (isCheckIn) {
      return 'Checked In';
    } else {
      return 'Checked Out';
    }
  }
}
