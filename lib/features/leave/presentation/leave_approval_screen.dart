import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/leave_service.dart';

class LeaveApprovalScreen extends ConsumerStatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  ConsumerState<LeaveApprovalScreen> createState() =>
      _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends ConsumerState<LeaveApprovalScreen> {
  List<NotificationModel> _pending = [];
  List<NotificationModel> _recent = [];
  bool _loading = true;
  String? _error;
  // Cache of live details keyed by leaveId
  final Map<String, Map<String, dynamic>> _leaveDetails = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  // Determine user level based on position name
  String _getUserLevel(AuthService auth) {
    final position = auth.currentPositionName ?? '';

    // Check if user is HR
    if (position.toLowerCase().contains('hr') ||
        position.toLowerCase().contains('human resource')) {
      return 'hr';
    }

    // Check if user is an approver
    if (position.toLowerCase().contains('approver')) {
      return 'approver';
    }

    // Default to manager (most common case)
    return 'manager';
  }

  Widget _detailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPending() async {
    final auth = ref.read(authServiceProvider);
    final currentEmployeeId = auth.currentEmployeeId;
    if (currentEmployeeId == null) {
      setState(() {
        _loading = false;
        _error = 'User not logged in';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Determine user level (manager/hr/approver) based on user role or permissions
      final userLevel = _getUserLevel(auth);
      print('🔍 DEBUG: User level determined as: $userLevel');
      print('🔍 DEBUG: User position: ${auth.currentPositionName}');
      print('🔍 DEBUG: User employee ID: $currentEmployeeId');

      // Fetch leave requests that need approval based on user level and permissions
      final leaveService = LeaveService();

      // All users (HR, managers, approvers) should use the approval endpoint
      // The backend now correctly handles HR requests with approved_manager status
      List<Map<String, dynamic>> leaveRequests;
      try {
        leaveRequests = await leaveService.getLeaveRequestsForApproval(
          userLevel,
          currentEmployeeId,
        );
        print(
          '🔍 DEBUG: API returned ${leaveRequests.length} leave requests for $userLevel',
        );
      } catch (e) {
        print('❌ DEBUG: Error getting leave requests: $e');
        leaveRequests = [];
      }

      print('🔍 DEBUG: Found ${leaveRequests.length} leave requests');
      print('🔍 DEBUG: Current user ID: $currentEmployeeId');

      // Debug: Print all leave requests
      for (int i = 0; i < leaveRequests.length; i++) {
        final request = leaveRequests[i];
        print('🔍 DEBUG: Leave request $i:');
        print('  - ID: ${request['id']}');
        print('  - Employee ID: ${request['employeeId']}');
        print('  - Employee Name: ${request['employeeName']}');
        print('  - Status: ${request['status']}');
        print('  - Leave Type: ${request['leaveTypeName']}');
        print('  - Company: ${request['company']} / ${request['companyName']}');
        print(
          '  - Location: ${request['location']} / ${request['locationName']}',
        );
        print('  - Branch: ${request['branch']} / ${request['branchName']}');
      }

      // Filter pending leave requests directly
      final List<Map<String, dynamic>> pendingRequests = [];

      for (final leaveRequest in leaveRequests) {
        print('🔍 DEBUG: Checking leave request ${leaveRequest['id']}:');
        print('  - employeeId: ${leaveRequest['employeeId']}');
        print('  - currentEmployeeId: $currentEmployeeId');
        print('  - status: ${leaveRequest['status']}');
        print(
          '  - isDifferentEmployee: ${leaveRequest['employeeId'] != currentEmployeeId}',
        );
        print(
          '  - isPending: ${leaveRequest['status'] == 'pending' || leaveRequest['status'] == 'sent'}',
        );

        // Filter for leave requests that need attention (not from current user)
        // The backend now handles the status filtering correctly, so we just need to exclude current user's requests
        if (leaveRequest['employeeId'] != currentEmployeeId) {
          print(
            '✅ DEBUG: Adding to pending requests (status: ${leaveRequest['status']}, userLevel: $userLevel)',
          );
          pendingRequests.add(leaveRequest);
        } else {
          print(
            '❌ DEBUG: Skipping this request (same user: ${leaveRequest['employeeId']})',
          );
        }
      }

      print(
        '🔍 DEBUG: Final pending requests count: ${pendingRequests.length}',
      );

      setState(() {
        _pending = pendingRequests
            .map(
              (request) => NotificationModel(
                id: request['id'] ?? '',
                title: 'Leave Request',
                message:
                    'New leave request from ${request['employeeName'] ?? 'Employee'}',
                type: 'leave_request',
                userId: currentEmployeeId,
                senderId: request['employeeId'],
                data: request,
                createdAt:
                    DateTime.tryParse(request['createdAt'] ?? '') ??
                    DateTime.now(),
                updatedAt: DateTime.now(),
                isRead: false,
              ),
            )
            .toList();
        _recent = [];
        _loading = false;
      });

      print('🔍 DEBUG: Loaded ${_pending.length} pending approvals');
    } catch (e) {
      print('❌ DEBUG: Error loading leave requests: $e');
      setState(() {
        _loading = false;
        _error = 'Error loading approvals: $e';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text(
          'Team Leave Approvals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.kOnBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildLeaveApprovalContent(),
    );
  }

  Widget _buildLeaveApprovalContent() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPendingApprovals(),
          const SizedBox(height: 24),
          _buildRecentApprovals(),
        ],
      ),
    );
  }

  Widget _buildPendingApprovals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Approvals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_error!, style: TextStyle(color: AppTheme.errorColor)),
          )
        else if (_pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No pending requests',
              style: TextStyle(color: AppTheme.kOnSurface.withOpacity(0.7)),
            ),
          )
        else
          ..._pending.map((n) => _buildPendingApprovalCard(n)),
      ],
    );
  }

  Widget _buildPendingApprovalCard(NotificationModel notification) {
    // Extract clean leave type from title (remove "New Leave Request from..." prefix)
    final rawTitle = notification.title;
    final leaveType = rawTitle.contains('New Leave Request from')
        ? rawTitle.split('New Leave Request from').last.trim()
        : rawTitle;

    // Try multiple sources for employee name
    String employeeName = '';
    if (notification.data['employeeName'] != null &&
        notification.data['employeeName'].toString().isNotEmpty) {
      employeeName = notification.data['employeeName'].toString();
    } else if (notification.data['firstName'] != null &&
        notification.data['lastName'] != null) {
      employeeName =
          '${notification.data['firstName']} ${notification.data['lastName']}';
    } else if (notification.data['name'] != null &&
        notification.data['name'].toString().isNotEmpty) {
      employeeName = notification.data['name'].toString();
    } else if (notification.data['senderName'] != null &&
        notification.data['senderName'].toString().isNotEmpty) {
      employeeName = notification.data['senderName'].toString();
    } else {
      employeeName = 'Employee ${notification.senderId ?? 'Unknown'}';
    }

    final positionName =
        notification.data['positionName'] ??
        notification.data['position'] ??
        notification.data['senderPosition'] ??
        '';
    final employeeId =
        notification.data['employeeId'] ??
        notification.data['senderId'] ??
        notification.senderId ??
        '';

    // Debug: Print notification data to see what's available
    print('🔍 DEBUG: Building card for notification:');
    print('  - notification.data: ${notification.data}');
    print('  - rawTitle: $rawTitle');
    print('  - leaveType (cleaned): $leaveType');
    print('  - employeeName: $employeeName');
    print('  - positionName: $positionName');
    print('  - employeeId: $employeeId');

    // Prefer live detail status if available
    final leaveId =
        notification.data['leaveRequestId'] ??
        notification.data['leaveId'] ??
        notification.data['id'];
    final live = leaveId != null ? _leaveDetails[leaveId] : null;
    final rawStatus =
        (live?['status'] ??
                live?['statusName'] ??
                notification.data['status'] ??
                notification.data['statusName'] ??
                'pending')
            .toString();
    final statusLower = rawStatus.toLowerCase();
    // Determine if action buttons should be shown based on user role and status
    final userLevel = _getUserLevel(ref.read(authServiceProvider));
    final isPendingOrSent = statusLower == 'pending' || statusLower == 'sent';
    final isApprovedByManager =
        statusLower == 'approved_manager' ||
        statusLower == 'approved_by_manager' ||
        (statusLower.contains('approved') && statusLower.contains('manager'));

    // HR can act on pending/sent AND approved_by_manager requests
    // Managers/Approvers can only act on pending/sent requests
    final showActions =
        isPendingOrSent || (userLevel == 'hr' && isApprovedByManager);

    // Debug: Print status info
    print('  - rawStatus: $rawStatus');
    print('  - statusLower: $statusLower');
    print('  - showActions: $showActions');

    return GestureDetector(
      onTap: () => _showLeaveDetails(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.kNanoGold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.kNanoGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.kNanoGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee name (first line)
                      Text(
                        employeeName.isNotEmpty
                            ? employeeName
                            : 'Employee ${notification.senderId ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Employee ID (second line)
                      Text(
                        employeeId.isNotEmpty ? employeeId : 'ID: Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Position name (third line)
                      Text(
                        positionName.isNotEmpty
                            ? positionName
                            : 'Position: Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge (moved to right side of top row)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusLower == 'approved'
                        ? Colors.green.withOpacity(0.1)
                        : statusLower == 'rejected'
                        ? Colors.red.withOpacity(0.1)
                        : statusLower == 'approved_manager' ||
                              statusLower == 'approved_by_manager' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('manager'))
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLower == 'approved'
                        ? 'Approved'
                        : statusLower == 'rejected'
                        ? 'Rejected'
                        : statusLower == 'approved_manager' ||
                              statusLower == 'approved_by_manager' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('manager'))
                        ? 'Approved by Manager'
                        : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusLower == 'approved'
                          ? Colors.green[700]
                          : statusLower == 'rejected'
                          ? Colors.red[700]
                          : statusLower == 'approved_manager' ||
                                statusLower == 'approved_by_manager' ||
                                (statusLower.contains('approved') &&
                                    statusLower.contains('manager'))
                          ? Colors.blue[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            // Action buttons (moved under the employee details)
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDecision(
                          notification: notification,
                          approve: false,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[600],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red[200]!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDecision(
                          notification: notification,
                          approve: true,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green[600],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.green[200]!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaveDetails(NotificationModel notification) async {
    final leaveId =
        notification.data['leaveRequestId'] ??
        notification.data['leaveId'] ??
        notification.data['id'];
    print('🔍 DEBUG: Tap detected, leaveId = $leaveId');
    print('🔍 DEBUG: notification.data = ${notification.data}');
    if (leaveId == null) {
      print('❌ DEBUG: No leaveId found, cannot show details');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No leave ID found')));
      return;
    }

    // Try cache first
    Map<String, dynamic>? details = _leaveDetails[leaveId];
    if (details == null) {
      final service = LeaveService();
      final res = await service.getLeaveDetails(leaveId);
      print('🔍 DEBUG: Leave details API response: $res');
      if (res['success'] == true) {
        final lr = res['leaveRequest'] ?? res['data'] ?? {};
        print('🔍 DEBUG: Leave request data: $lr');
        print('🔍 DEBUG: Available fields in response:');
        lr.forEach((key, value) {
          print('  - $key: $value');
        });
        // Use notification data which already has complete employee information
        print('🔍 DEBUG: Using notification data for employee info');
        print('🔍 DEBUG: notification.data: ${notification.data}');

        details = {
          'leaveTypeName':
              lr['leaveTypeName'] ?? lr['leaveType'] ?? lr['requestType'],
          'fromDate': lr['fromDate'],
          'toDate': lr['toDate'],
          'totalDays': lr['totalDays'],
          'requestType': lr['requestType'],
          'reason': lr['reason'],
          'status': lr['status'] ?? lr['statusName'],
          'approvedByName': lr['approvedByName'],
          'employeeName':
              notification.data['employeeName'] ??
              lr['employeeName'] ??
              (lr['firstName'] != null && lr['lastName'] != null
                  ? '${lr['firstName']} ${lr['lastName']}'
                  : lr['firstName'] ?? lr['lastName'] ?? 'Unknown Employee'),
          'firstName': notification.data['firstName'] ?? lr['firstName'],
          'lastName': notification.data['lastName'] ?? lr['lastName'],
          'positionName':
              notification.data['positionName'] ??
              lr['positionName'] ??
              lr['position'] ??
              'Unknown Position',
          'employeeId':
              notification.data['employeeId'] ??
              lr['employeeId'] ??
              lr['employee_id'] ??
              'Unknown ID',
          'attachments': (() {
            try {
              final attachment = lr['attachment'];
              if (attachment is Map<String, dynamic>) {
                final files = attachment['files'];
                if (files is List) {
                  return files
                      .map((e) => e['publicUrl']?.toString())
                      .whereType<String>()
                      .toList();
                }
              }
              return <String>[];
            } catch (e) {
              print('❌ DEBUG: Attachment parsing error: $e');
              return <String>[];
            }
          })(),
        };
        _leaveDetails[leaveId] = details;
      }
    }

    if (!mounted) return;

    // If no details found, show notification details as fallback
    if (details == null) {
      _showNotificationDetails(notification);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final d = details ?? {};
        final status = (d['status'] ?? 'Pending').toString();
        final statusLower = status.toLowerCase();
        final Color statusColor = statusLower == 'approved'
            ? AppTheme.successColor
            : statusLower == 'rejected'
            ? AppTheme.errorColor
            : AppTheme.warningColor;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.kNanoGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: AppTheme.kNanoGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['leaveTypeName']?.toString() ??
                                d['requestType']?.toString() ??
                                d['leaveType']?.toString() ??
                                'Leave Request',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d['employeeName']?.toString() ?? 'Unknown Employee'} • ${d['positionName']?.toString() ?? 'Unknown Position'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // All details in a clean list format
                _detailRow('From', d['fromDate']),
                _detailRow('To', d['toDate']),
                _detailRow('Total Days', d['totalDays']?.toString()),
                _detailRow('Request Type', d['requestType']),
                _detailRow('Reason', d['reason']),
                if (d['employeeName'] != null)
                  _detailRow('Employee Name', d['employeeName']),
                if (d['positionName'] != null)
                  _detailRow('Position', d['positionName']),
                if (d['employeeId'] != null)
                  _detailRow('Employee ID', d['employeeId']),
                if (d['approvedByName'] != null)
                  _detailRow('Approved By', d['approvedByName']),
                const SizedBox(height: 8),
                if (d['attachments'] != null &&
                    (d['attachments'] as List).isNotEmpty) ...[
                  const Text(
                    'Attachments',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: (d['attachments'] as List).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final url = (d['attachments'] as List)[index] as String;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 120,
                            height: 84,
                            color: Colors.grey.withOpacity(0.1),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final data = notification.data;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow('Message', notification.message),
                _detailRow('Type', notification.type),
                _detailRow('Sender ID', notification.senderId),
                _detailRow('Created', notification.createdAt.toString()),
                _detailRow('Employee Name', data['employeeName']?.toString()),
                _detailRow('Date Range', data['dateRange']?.toString()),
                _detailRow('Duration', data['duration']?.toString()),
                _detailRow('Status', data['status']?.toString()),
                const SizedBox(height: 8),
                const Text(
                  'All Data:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentApprovals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Approvals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
            ),
          )
        else if (_recent.isEmpty)
          Text(
            'No recent approvals',
            style: TextStyle(color: AppTheme.kOnSurface.withOpacity(0.7)),
          )
        else
          ..._recent.map((n) => _buildRecentApprovalCard(n)),
      ],
    );
  }

  Widget _buildRecentApprovalCard(NotificationModel notification) {
    final approved = notification.type == 'leave_approved';
    final status = approved ? 'Approved' : 'Rejected';
    final statusColor = approved ? Colors.green : Colors.red;
    final employeeName = notification.data['employeeName'] ?? '';
    final leaveType = notification.title.isNotEmpty
        ? notification.title
        : 'Leave Request';
    final duration = notification.data['duration']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                approved ? Icons.check_circle : Icons.cancel,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leaveType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employeeName.isNotEmpty ? employeeName : (notification.senderId ?? '')}${duration.isNotEmpty ? ' • $duration' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDecision({
    required NotificationModel notification,
    required bool approve,
  }) async {
    final actionText = approve ? 'Approve' : 'Reject';
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${actionText.toLowerCase()} this request?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _decide(notification, approve, noteController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    NotificationModel notification,
    bool approve,
    String note,
  ) async {
    final auth = ref.read(authServiceProvider);
    final approverId = auth.currentEmployeeId;
    if (approverId == null) return;

    final leaveId =
        notification.data['leaveRequestId'] ??
        notification.data['leaveId'] ??
        notification.data['id'] ??
        '';
    if (leaveId.isEmpty) {
      _showSuccessMessage('Missing leave ID');
      return;
    }

    final service = LeaveService();
    // Verify current status first - but allow HR to act on manager-approved requests
    final details = await service.getLeaveDetails(leaveId);
    if (details['success'] == true) {
      final currentStatus =
          details['leaveRequest']?['status'] ??
          details['data']?['status'] ??
          details['status'];

      final userLevel = _getUserLevel(auth);
      final statusLower = currentStatus?.toString().toLowerCase() ?? '';

      // Check if user can act on this status
      final canAct = userLevel == 'hr'
          ? (statusLower == 'pending' ||
                statusLower == 'approved_manager' ||
                statusLower == 'approved_by_manager')
          : (statusLower == 'pending' || statusLower == 'sent');

      if (currentStatus != null && !canAct) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This request is already $currentStatus. Refreshing list.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        await _loadPending();
        return;
      }
    }
    // Prefer the status endpoint; backend also supports approval path
    final status = approve ? 'approved' : 'rejected';
    final userRole = _getUserLevel(auth);
    final res = await service.updateLeaveStatus(
      leaveId: leaveId,
      status: status,
      approverId: approverId,
      userRole: userRole,
      note: note,
    );

    if (res['success'] == true) {
      _showSuccessMessage(
        approve
            ? 'Leave request approved successfully!'
            : 'Leave request rejected.',
      );
      await _loadPending();
    } else {
      // Fallback: try the alternate endpoint once
      final alt = await service.approveOrRejectLeave(
        leaveId: leaveId,
        action: approve ? 'approve' : 'reject',
        approverId: approverId,
        userRole: userRole,
        note: note,
      );
      if (alt['success'] == true) {
        _showSuccessMessage(
          approve
              ? 'Leave request approved successfully!'
              : 'Leave request rejected.',
        );
        await _loadPending();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              alt['message'] ?? res['message'] ?? 'Failed to update leave',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }
}
