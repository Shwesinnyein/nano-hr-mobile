class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: (json['userId'] ?? json['recipientId']) as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['isRead'] == true || json['isRead'] == 'true',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get timeAgo => _getTimeAgo(createdAt);
  bool get isImportant => _isImportantNotification(type, title);
  String get displayType => _getDisplayType(type);

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  bool _isImportantNotification(String type, String title) {
    // Mark certain types as important
    if (type == 'leave_rejected' ||
        type == 'leave_request' ||
        title.toLowerCase().contains('urgent') ||
        title.toLowerCase().contains('emergency')) {
      return true;
    }
    return false;
  }

  String _getDisplayType(String type) {
    switch (type) {
      case 'leave_request':
        return 'Leave Request';
      case 'leave_approved':
        return 'Leave Approved';
      case 'leave_rejected':
        return 'Leave Rejected';
      case 'leave_reminder':
        return 'Leave Reminder';
      case 'policy':
        return 'Policy Update';
      case 'system':
        return 'System';
      case 'meeting':
        return 'Meeting';
      case 'payroll':
        return 'Payroll';
      case 'celebration':
        return 'Celebration';
      default:
        return 'Notification';
    }
  }
}

class NotificationPagination {
  final int totalNotifications;
  final int totalPages;
  final int currentPage;
  final int limit;

  NotificationPagination({
    required this.totalNotifications,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      totalNotifications: json['totalNotifications'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      limit: json['limit'] as int,
    );
  }
}

class NotificationResponse {
  final bool success;
  final String message;
  final List<NotificationModel> notifications;
  final NotificationPagination? pagination;

  NotificationResponse({
    required this.success,
    required this.message,
    required this.notifications,
    this.pagination,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final notificationsList = (json['data'] as List<dynamic>)
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    NotificationPagination? pagination;
    if (json['pagination'] != null) {
      pagination = NotificationPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      );
    }

    return NotificationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      notifications: notificationsList,
      pagination: pagination,
    );
  }
}
