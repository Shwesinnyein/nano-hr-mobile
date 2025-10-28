import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    // Initialize notification count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).initialize();
    });
  }

  void _getCurrentUserId() {
    final authService = ref.read(authServiceProvider);
    _currentUserId = authService.currentEmployeeId;
    if (_currentUserId != null) {
      // Clear cache to get fresh data from server
      _notificationService.clearCache();
      _loadNotifications();
      // Skip separate badge count refresh to reduce API calls
      // The badge count will be updated when notifications are loaded
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _notificationService.getNotifications(
        employeeId: _currentUserId!,
        limit: 50, // Load more notifications
      );

      if (response['success'] == true) {
        try {
          final notificationResponse = NotificationResponse.fromJson(response);

          final filteredNotifications = _filterNotifications(
            notificationResponse.notifications,
            _currentUserId!,
          );

          setState(() {
            _notifications = filteredNotifications;
            _isLoading = false;
          });

          // Update badge count based on loaded notifications
          final unreadCount = filteredNotifications
              .where((n) => !n.isRead)
              .length;
          ref
              .read(notificationProvider.notifier)
              .updateUnreadCount(unreadCount);
        } catch (parseError) {
          setState(() {
            _error = 'Error parsing notifications: $parseError';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      final cachedData = NotificationService.notificationCache[_currentUserId!];
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final notificationResponse = NotificationResponse.fromJson({
            'success': true,
            'data': cachedData,
            'message': 'Using cached data',
          });

          final filteredNotifications = _filterNotifications(
            notificationResponse.notifications,
            _currentUserId!,
          );

          setState(() {
            _notifications = filteredNotifications;
            _isLoading = false;
            _error = 'Using cached data - API connection issue';
          });

          // Update badge count based on cached notifications
          final unreadCount = filteredNotifications
              .where((n) => !n.isRead)
              .length;
          ref
              .read(notificationProvider.notifier)
              .updateUnreadCount(unreadCount);
        } catch (parseError) {
          setState(() {
            _error =
                'Error loading notifications: $e (cached data also failed)';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Error loading notifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Filter notifications based on user role and context
  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
    String currentEmployeeId,
  ) {
    // 1) Base filtering rules
    final filtered = notifications.where((notification) {
      // Hide self-originated leave_request (employee shouldn't see their own request)
      if (notification.type == 'leave_request') {
        // If sender is missing or equals current user, hide it (defensive until backend fixes senderId)
        if (notification.senderId == null ||
            notification.senderId == currentEmployeeId) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2) De-duplicate potential duplicates from backend (same leave request emitted twice)
    final Map<String, NotificationModel> uniqueByKey = {};
    for (final n in filtered) {
      final leaveId = n.data['leaveRequestId'] ?? n.data['leaveId'] ?? '';
      final coarseTimeBucket =
          n.createdAt.millisecondsSinceEpoch ~/ 60000; // 1-minute bucket
      final key =
          '${n.type}:$leaveId:${n.title}:${n.message}:$coarseTimeBucket';
      // Keep the first occurrence (usually the earlier one), or replace with the latest if needed
      if (!uniqueByKey.containsKey(key)) {
        uniqueByKey[key] = n;
      }
    }

    return uniqueByKey.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _refreshNotifications() async {
    if (_currentUserId == null) {
      return;
    }

    // Clear cache to force fresh data from server
    _notificationService.clearCache();
    await _loadNotifications();

    ref.read(notificationProvider.notifier).refreshUnreadCount();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (_currentUserId == null) return;

    try {
      final response = await _notificationService.markAsRead(
        employeeId: _currentUserId!,
        notificationId: notification.id,
      );

      if (response['success'] == true) {
        setState(() {
          // Update the notification in the list
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              data: notification.data,
              isRead: true, // Mark as read
              createdAt: notification.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });

        // Update the badge count
        ref.read(notificationProvider.notifier).markAsRead();
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to mark as read');
      }
    } catch (e) {
      _showErrorSnackBar('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final response = await _notificationService.markAllAsRead(
        employeeId: _currentUserId!,
      );

      if (response['success'] == true) {
        // Reload notifications to get updated read status
        await _loadNotifications();

        // Update the badge count to 0
        ref.read(notificationProvider.notifier).markAllAsRead();

        _showSuccessSnackBar(
          response['message'] ?? 'All notifications marked as read',
        );
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to mark all as read');
      }
    } catch (e) {
      _showErrorSnackBar('Error marking all as read: $e');
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    await _markAsRead(notification);

    // Get current user ID for filtering
    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    // Navigate based on notification type and user role
    switch (notification.type) {
      case 'leave_request':
      case 'pending_approval':
      case 'approved_manager':
      case 'approved_by_manager':
      case 'approved_team_lead':
      case 'approved_by_team_lead':
      case 'pending_hr_approval':
      case 'pending_approver_approval':
        // Navigate to leave approval screen for users who need to approve
        // (managers, team leads, HR, approvers)
        // Regular employees should NOT see their own leave request notifications
        if (currentEmployeeId != null &&
            notification.senderId == currentEmployeeId) {
          return;
        }

        // Navigate to leave approval screen (for all user types)
        // The LeaveApprovalScreen automatically determines user level:
        // - HR: sees pending and manager-approved requests
        // - Approver: sees pending and HR-approved requests  
        // - Team Lead: sees pending requests from team
        // - Manager: sees pending requests from employees
        if (mounted) {
          context.push('/leave/approval');
        }
      case 'leave_approved':
      case 'leave_approved_by_team_lead':
      case 'leave_approved_by_manager':
      case 'leave_approved_by_hr':
      case 'approved_team_lead':
      case 'approved_manager':
      case 'approved_hr':
      case 'approved':
      case 'leave_rejected':
      case 'leave_rejected_by_team_lead':
      case 'leave_rejected_by_manager':
      case 'leave_rejected_by_hr':
      case 'rejected':
        // Navigate to leave list to see the status (for employees)
        if (mounted) {
          context.push('/leave/list');
        }
      default:
        // For other notification types, just mark as read
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

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
            icon: Icon(Icons.refresh, color: AppTheme.kOnBackground),
            onPressed: _refreshNotifications,
          ),
          IconButton(
            icon: Icon(Icons.mark_email_read, color: AppTheme.kOnBackground),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: Column(
          children: [
            _buildNotificationSummary(),
            Expanded(child: _buildNotificationList()),
          ],
        ),
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
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
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _refreshNotifications();
              },
              child: const Text('Debug: Refresh Notifications'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Debug: Print notification type to console
    print('Notification type: ${notification.type}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  int _getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  Color _getNotificationColor(String type) {
    // Use string matching for more flexibility
    if (type.contains('approved') || type.contains('approve')) {
      return AppTheme.successColor;
    }
    if (type.contains('rejected') || type.contains('reject')) {
      return AppTheme.errorColor;
    }
    
    switch (type) {
      case 'leave_request':
      case 'pending':
        return AppTheme.kNanoGold;
      case 'leave_reminder':
        return AppTheme.warningColor;
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
    // Use string matching for more flexibility
    if (type.contains('approved') || type.contains('approve')) {
      return Icons.check_circle;
    }
    if (type.contains('rejected') || type.contains('reject')) {
      return Icons.cancel;
    }
    
    switch (type) {
      case 'leave_request':
      case 'pending':
        return Icons.calendar_today;
      case 'leave_reminder':
        return Icons.schedule;
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
}
