import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/providers/language_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).initialize();
    });
  }

  void _getCurrentUserId() {
    final authService = ref.read(authServiceProvider);
    _currentUserId = authService.currentEmployeeId;
    if (_currentUserId != null) {
      _notificationService.clearCache();
      _loadNotifications();
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
        limit: 50, 
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

          final unreadCount = filteredNotifications
              .where((n) => !n.isRead)
              .length;
          ref
              .read(notificationProvider.notifier)
              .updateUnreadCount(unreadCount);
          
          final pushService = ref.read(pushNotificationServiceProvider);
          await pushService.updateBadgeCount(unreadCount);
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

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
    String currentEmployeeId,
  ) {
    final filtered = notifications.where((notification) {
      
      if (notification.type == 'leave_request') {
        if (notification.senderId == currentEmployeeId) {
          return false; 
        }
      }
      
      if (notification.userId != currentEmployeeId) {
        return false; 
      }
      
      
      return true;
    }).toList();

    final Map<String, NotificationModel> uniqueByKey = {};
    for (final n in filtered) {
      final leaveId = n.data['leaveRequestId'] ?? n.data['leaveId'] ?? '';
      final coarseTimeBucket =
          n.createdAt.millisecondsSinceEpoch ~/ 60000; 
      final key =
          '${n.type}:$leaveId:${n.title}:${n.message}:$coarseTimeBucket';
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
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              titleTh: notification.titleTh,
              messageTh: notification.messageTh,
              type: notification.type,
              data: notification.data,
              isRead: true, 
              createdAt: notification.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });

        ref.read(notificationProvider.notifier).markAsRead();
        
        final unreadCount = _notifications.where((n) => !n.isRead).length;
        final pushService = ref.read(pushNotificationServiceProvider);
        await pushService.updateBadgeCount(unreadCount);
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
      // Show loading state
      setState(() {
        _isLoading = true;
      });

      // Call API to mark all as read
      final response = await _notificationService.markAllAsRead(
        employeeId: _currentUserId!,
      );

      if (response['success'] == true) {
        // Update local state immediately
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            final n = _notifications[i];
            _notifications[i] = NotificationModel(
              id: n.id,
              userId: n.userId,
              senderId: n.senderId,
              title: n.title,
              message: n.message,
              titleTh: n.titleTh,
              messageTh: n.messageTh,
              type: n.type,
              data: n.data,
              isRead: true, 
              createdAt: n.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });

        // Update provider and badge count
        ref.read(notificationProvider.notifier).markAllAsRead();
        final pushService = ref.read(pushNotificationServiceProvider);
        await pushService.updateBadgeCount(0);

        // Clear cache and reload notifications to get fresh data from server
        _notificationService.clearCache();
        await _loadNotifications();
        
        // Refresh the unread count
        ref.read(notificationProvider.notifier).refreshUnreadCount();

        _showSuccessSnackBar(
          ref.t('ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว', 'All notifications marked as read'),
        );
      } else {
        await _loadNotifications();
        _showErrorSnackBar(
          ref.t('ไม่สามารถทำเครื่องหมายว่าอ่านได้', response['message'] ?? 'Failed to mark all as read'),
        );
      }
    } catch (e) {
      await _loadNotifications();
      _showErrorSnackBar(ref.t('เกิดข้อผิดพลาด', 'Error marking all as read: $e'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Leave notifications (request, approve, reject) always have a leave ID in data.
  /// Backend may send it as leaveRequestId, leaveId, or leave_id.
  String _getLeaveIdFromNotification(NotificationModel notification) {
    final d = notification.data;
    final value = d['leaveRequestId'] ?? d['leaveId'] ?? d['leave_id'] ?? '';
    return value.toString().trim();
  }

  void _handleNotificationTap(NotificationModel notification) async {   
    await _markAsRead(notification);

    // Leave notifications (request, approve, reject) always include a leave ID in data
    final leaveId = _getLeaveIdFromNotification(notification);
    final hasLeaveId = leaveId.isNotEmpty;

    if (hasLeaveId && mounted) {
      context.push('/leave/detail/$leaveId', extra: notification);
      return;
    }

    // Fallback: no leave ID in data — use list or approval by type
    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    final isOwnRequest = currentEmployeeId != null && 
                        notification.senderId == currentEmployeeId;
    
    final type = notification.type.toLowerCase();
    final title = notification.title.toLowerCase();
    final message = notification.message.toLowerCase();
    
    final isLeaveRequestNotification = type == 'leave_request' || 
                                       type == 'pending' ||
                                       title.contains('leave request') ||
                                       message.contains('submitted') ||
                                       message.contains('leave request');
    
    final isRejectedNotification = type == 'rejected' ||
                                   title.contains('rejected') ||
                                   message.contains('rejected');
    
    final isApprovedNotification = type == 'approved' ||
                                   title.contains('approved') ||
                                   (message.contains('approved') && !message.contains('rejected'));
    
    final isApprovalWorkflow = type == 'approved_team_lead' ||
                               type == 'approved_manager' ||
                               type == 'approved_hr' ||
                               type == 'approved_warehouse_manager' ||
                               type == 'approved_by_warehouse_manager';
    
    if (isRejectedNotification) {
      if (mounted) context.push('/leave/list');
    } else if (isApprovedNotification && isOwnRequest) {
      if (mounted) context.push('/leave/list');
    } else if (isLeaveRequestNotification || isApprovalWorkflow) {
      if (isOwnRequest) {
        if (mounted) context.push('/leave/list');
      } else {
        if (mounted) context.push('/leave/approval');
      }
    } else {
      switch (notification.type) {
        case 'pending':
        case 'approved_team_lead':
        case 'approved_manager':
        case 'approved_hr':
        case 'approved_warehouse_manager':
        case 'approved_by_warehouse_manager':
          if (isOwnRequest) {
            if (mounted) context.push('/leave/list');
            return;
          }
          if (mounted) context.push('/leave/approval');
          break;
        case 'approved':
        case 'rejected':
          if (mounted) context.push('/leave/list');
          break;
        default:
          break;
      }
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
        title: Text(
          ref.t('การแจ้งเตือน', 'Notifications'),
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
                  ref.t('การแจ้งเตือน', 'Notifications'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNanoWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.t(
                    '${_getUnreadCount()} การแจ้งเตือนที่ยังไม่ได้อ่าน',
                    '${_getUnreadCount()} unread notifications',
                  ),
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
              child: Text(ref.t('ลองอีกครั้ง', 'Retry')),
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
              ref.t('ไม่มีการแจ้งเตือน', 'No notifications'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.t('ดึงลงเพื่อรีเฟรช', 'Pull down to refresh'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: () {
            //     _refreshNotifications();
            //   },
            //   child: const Text('Debug: Refresh Notifications'),
            // ),
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
                              notification.getLocalizedTitle(ref.watch(languageProvider)),
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
                        notification.getLocalizedMessage(ref.watch(languageProvider)),
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
    if (type.contains('leave') || type == 'leave_request' || type == 'pending') {
      if (type.contains('approved') || type.contains('approve')) {
        return Icons.check_circle; 
      }
      if (type.contains('rejected') || type.contains('reject')) {
        return Icons.cancel; 
      }
      return Icons.calendar_today;
    }
    
   
    if (type.contains('approved') || type.contains('approve')) {
      return Icons.check_circle;
    }
    if (type.contains('rejected') || type.contains('reject')) {
      return Icons.cancel;
    }
    
    switch (type) {
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
