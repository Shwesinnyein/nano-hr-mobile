import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read, color: AppTheme.kOnBackground),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNotificationSummary(),
          Expanded(child: _buildNotificationList()),
        ],
      ),
    );
  }

  Widget _buildNotificationSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kNanoWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications,
              color: AppTheme.kNanoWhite,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNanoWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getUnreadCount()} unread notifications',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.kNanoWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifications = _getSampleNotifications();

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.withOpacity(0.2)
                  : AppTheme.kNanoGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.kOnSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.kNanoGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        if (notification.isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Important',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NotificationData> _getSampleNotifications() {
    return [
      NotificationData(
        id: '1',
        title: 'Leave Request Approved',
        message:
            'Your annual leave request for March 15-20, 2024 has been approved by HR Manager.',
        type: 'leave',
        isRead: false,
        isImportant: false,
        timeAgo: '2 hours ago',
      ),
      NotificationData(
        id: '2',
        title: 'Sick Leave Request Pending',
        message:
            'Your sick leave request for today is under review. Please provide medical certificate.',
        type: 'leave',
        isRead: false,
        isImportant: true,
        timeAgo: '4 hours ago',
      ),
      NotificationData(
        id: '3',
        title: 'Leave Request Rejected',
        message:
            'Your casual leave request for March 25-26 was rejected due to insufficient balance.',
        type: 'leave',
        isRead: true,
        isImportant: false,
        timeAgo: '1 day ago',
      ),
      NotificationData(
        id: '4',
        title: 'Maternity Leave Approved',
        message:
            'Your maternity leave from April 1 to July 1, 2024 has been approved. Congratulations!',
        type: 'leave',
        isRead: true,
        isImportant: true,
        timeAgo: '2 days ago',
      ),
      NotificationData(
        id: '5',
        title: 'Leave Balance Update',
        message:
            'Your annual leave balance has been updated. You now have 8 days remaining.',
        type: 'leave',
        isRead: false,
        isImportant: false,
        timeAgo: '3 days ago',
      ),
      NotificationData(
        id: '6',
        title: 'Emergency Leave Request',
        message:
            'Your emergency leave request for family emergency has been approved immediately.',
        type: 'leave',
        isRead: true,
        isImportant: true,
        timeAgo: '1 week ago',
      ),
      NotificationData(
        id: '7',
        title: 'Study Leave Approved',
        message:
            'Your study leave for professional certification exam on March 30 has been approved.',
        type: 'leave',
        isRead: false,
        isImportant: false,
        timeAgo: '1 week ago',
      ),
      NotificationData(
        id: '8',
        title: 'Compensatory Leave Available',
        message:
            'You have 3 compensatory leave days available from overtime work last month.',
        type: 'leave',
        isRead: true,
        isImportant: false,
        timeAgo: '2 weeks ago',
      ),
      NotificationData(
        id: '9',
        title: 'Paternity Leave Reminder',
        message:
            'Your paternity leave application deadline is approaching. Please submit required documents.',
        type: 'leave',
        isRead: false,
        isImportant: true,
        timeAgo: '2 weeks ago',
      ),
      NotificationData(
        id: '10',
        title: 'Leave Policy Update',
        message:
            'HR has updated the leave policy. New rules for sick leave documentation apply from April 1.',
        type: 'policy',
        isRead: false,
        isImportant: true,
        timeAgo: '3 weeks ago',
      ),
    ];
  }

  int _getUnreadCount() {
    return _getSampleNotifications().where((n) => !n.isRead).length;
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'leave':
        return AppTheme.primaryColor;
      case 'policy':
        return AppTheme.warningColor;
      case 'system':
        return AppTheme.errorColor;
      case 'meeting':
        return AppTheme.secondaryColor;
      case 'payroll':
        return AppTheme.successColor;
      case 'celebration':
        return const Color(0xFFE91E63);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'leave':
        return Icons.calendar_today;
      case 'policy':
        return Icons.policy;
      case 'system':
        return Icons.settings;
      case 'meeting':
        return Icons.meeting_room;
      case 'payroll':
        return Icons.account_balance_wallet;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.notifications;
    }
  }

  void _markAllAsRead() {
    setState(() {
      // In a real app, this would update the notification status
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.kNanoGold,
      ),
    );
  }
}

class NotificationData {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final bool isImportant;
  final String timeAgo;

  NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.isImportant,
    required this.timeAgo,
  });
}
