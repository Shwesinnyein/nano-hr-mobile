import 'package:intl/intl.dart';

class Attendance {
  Attendance({
    required this.id,
    required this.userId,
    required this.checkInAt,
    this.checkOutAt,
    required this.location,
    this.employeeId,
    this.employeeName,
    this.duration,
  });

  final String id;
  final String userId;
  final DateTime checkInAt;
  DateTime? checkOutAt;
  final String location;
  final String? employeeId;
  final String? employeeName;
  final String? duration;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    print('🔍 Attendance.fromJson: Parsing JSON: $json');

    // Helper function to parse dates safely and convert to local time
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
          print(
            '⚠️ Attendance.fromJson: Unknown date format: $dateValue (${dateValue.runtimeType})',
          );
          return DateTime.now();
        }

        // Convert to local time if it's in UTC
        print(
          '🔍 Attendance.fromJson: Original date: $parsedDate (isUtc: ${parsedDate.isUtc})',
        );
        if (parsedDate.isUtc) {
          parsedDate = parsedDate.toLocal();
          print('🔍 Attendance.fromJson: Converted to local: $parsedDate');
        }

        print('🔍 Attendance.fromJson: Final date: $parsedDate (local time)');
        return parsedDate;
      } catch (e) {
        print('❌ Attendance.fromJson: Error parsing date $dateValue: $e');
        return DateTime.now();
      }
    }

    // Handle the backend response structure
    final timestamp = parseDate(json['timestamp'] ?? json['createdAt']);
    print('🔍 Attendance.fromJson: Timestamp: $timestamp');

    // Parse checkInAt and checkOutAt from the API response
    DateTime? checkInAt;
    DateTime? checkOutAt;

    if (json['checkInAt'] != null) {
      // Parse the time string (e.g., "09:07:16") and combine with today's date
      final timeValue = json['checkInAt'];
      if (timeValue != null) {
        final timeString = timeValue.toString();
        final today = DateTime.now();
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          checkInAt = DateTime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
            second,
          );
          print('🔍 Attendance.fromJson: Parsed checkInAt: $checkInAt');
        }
      }
    }

    if (json['checkOutAt'] != null) {
      // Parse the time string (e.g., "17:30:00") and combine with today's date
      final timeValue = json['checkOutAt'];
      if (timeValue != null) {
        final timeString = timeValue.toString();
        final today = DateTime.now();
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          checkOutAt = DateTime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
            second,
          );
          print('🔍 Attendance.fromJson: Parsed checkOutAt: $checkOutAt');
        }
      }
    }

    // Ensure we have a valid checkInAt
    final finalCheckInAt = checkInAt ?? timestamp;
    print('🔍 Attendance.fromJson: Final checkInAt: $finalCheckInAt');

    // Create attendance record
    return Attendance(
      id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      userId: json['employeeId']?.toString() ?? '',
      checkInAt: finalCheckInAt,
      checkOutAt: checkOutAt, // Keep null if no checkOutAt
      location: json['location']?.toString() ?? 'Office',
      employeeId: json['employeeId']?.toString(),
      employeeName: json['employeeName']?.toString(),
      duration: json['duration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInAt': checkInAt.toIso8601String(),
      'checkOutAt': checkOutAt?.toIso8601String(),
      'location': location,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'duration': duration,
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
