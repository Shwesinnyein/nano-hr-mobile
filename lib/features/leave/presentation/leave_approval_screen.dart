import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/leave_service.dart';
import '../data/leave_repository.dart';
import '../utils/leave_translations.dart';

class LeaveApprovalScreen extends ConsumerStatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  ConsumerState<LeaveApprovalScreen> createState() =>
      _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends ConsumerState<LeaveApprovalScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<NotificationModel> _pending = [];
  bool _loading = true;
  String? _error;
  
  final Map<String, Map<String, dynamic>> _leaveDetails = {};

  final Map<String, Map<String, dynamic>> _processedRequests = {};

  List<Map<String, dynamic>> _employeeLeaves = [];
  bool _loadingEmployeeLeaves = false;

  late TabController _tabController;
  int _currentTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllLeaveRequests(forceRefresh: true);
      _loadEmployeeLeaves();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadAllLeaveRequests(forceRefresh: true, showLoading: false);
    }
  }

  List<NotificationModel> _filterLeaveRequests(
    List<NotificationModel> requests,
  ) {
    if (_searchQuery.isEmpty) return requests;

    return requests.where((request) {
      final employeeName =
          request.data['employeeName']?.toString().toLowerCase() ?? '';
      final leaveType =
          request.data['leaveTypeName']?.toString().toLowerCase() ?? '';
      final reason = request.data['reason']?.toString().toLowerCase() ?? '';

      return employeeName.contains(_searchQuery) ||
          leaveType.contains(_searchQuery) ||
          reason.contains(_searchQuery);
    }).toList();
  }

  String _getUserLevel(AuthService auth) {
    final position = auth.currentPositionName ?? '';

    if (position.toLowerCase().contains('hr') ||
        position.toLowerCase().contains('human resource')) {
      return 'hr';
    }

    if (position.toLowerCase().contains('approver') ||
        position.toLowerCase().contains('management')) {
      return 'approver';
    }

    if (position.toLowerCase().contains('team lead')) {
      return 'team-lead';
    }

    if (position.toLowerCase().contains('programmer') ||
        position.toLowerCase().contains('developer')) {
      return 'team-lead';
    }

    return 'manager';
  }

  Future<void> _loadEmployeeLeaves({bool showLoading = true}) async {
    final auth = ref.read(authServiceProvider);
    final currentEmployeeId = auth.currentEmployeeId;
    if (currentEmployeeId == null) return;

    if (showLoading) {
      setState(() {
        _loadingEmployeeLeaves = true;
      });
    }

    try {
      final leaveService = LeaveService();
      final userLevel = _getUserLevel(auth);

      List<Map<String, dynamic>> allEmployeeLeaves = [];

      try {
        allEmployeeLeaves = await leaveService.getLeaveHistory(
          currentEmployeeId,
        );

        if (allEmployeeLeaves.isNotEmpty) {
          final sample = allEmployeeLeaves.first;
        } else {}
      } catch (e) {
        try {
          final processedLeaves = await leaveService
              .getLeaveRequestsForApproval(userLevel, currentEmployeeId);

          allEmployeeLeaves = processedLeaves.where((leave) {
            final approvalHistory =
                leave['approvalHistory'] as List<dynamic>? ?? [];
            return approvalHistory.any((history) {
              final historyUserId = history['userId']?.toString() ?? '';
              final historyLevel = history['level']?.toString() ?? '';
              return historyUserId == currentEmployeeId &&
                  historyLevel == userLevel;
            });
          }).toList();
        } catch (fallbackError) {
          allEmployeeLeaves = [];
        }
      }

      allEmployeeLeaves = allEmployeeLeaves.where((leave) {
        final employeeId = leave['employeeId']?.toString();
        return employeeId == null || employeeId != currentEmployeeId;
      }).toList();

      setState(() {
        _employeeLeaves = allEmployeeLeaves;
        _loadingEmployeeLeaves = false;
      });
    } catch (e) {
      setState(() {
        _loadingEmployeeLeaves = false;
      });
      // Error loading employee leaves handled silently
    }
  }

  List<Map<String, dynamic>> _filterEmployeeLeaves(
    List<Map<String, dynamic>> leaves,
  ) {
    if (_searchQuery.isEmpty) return leaves;

    return leaves.where((leave) {
      final employeeName =
          leave['employeeName']?.toString().toLowerCase() ?? '';
      final leaveType = leave['leaveTypeName']?.toString().toLowerCase() ?? '';
      final reason = leave['reason']?.toString().toLowerCase() ?? '';
      final status = leave['status']?.toString().toLowerCase() ?? '';

      return employeeName.contains(_searchQuery) ||
          leaveType.contains(_searchQuery) ||
          reason.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();
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

  Future<void> _loadAllLeaveRequests({bool showLoading = true, bool forceRefresh = false}) async {
    final auth = ref.read(authServiceProvider);
    final currentEmployeeId = auth.currentEmployeeId;
    if (currentEmployeeId == null) {
      setState(() {
        _loading = false;
        _error = 'User not logged in';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final userLevel = _getUserLevel(auth);
      final leaveService = LeaveService();
      
      if (forceRefresh) {
        LeaveService.clearApprovalCache();
      }

      List<Map<String, dynamic>> leaveRequests;
      try {
        leaveRequests = await leaveService.getAllLeaveRequestsForApproval(
          userLevel,
          currentEmployeeId,
        );
      } catch (e) {
        leaveRequests = [];
      }

      final List<Map<String, dynamic>> teamRequests = [];
      for (final leaveRequest in leaveRequests) {
        if (leaveRequest['employeeId'] != currentEmployeeId) {
          teamRequests.add(leaveRequest);
        }
      }

      final List<NotificationModel> pendingList = [];

      for (final request in teamRequests) {
        final notification = NotificationModel.fromJson({
          'id': request['id'] ?? '',
          'userId': currentEmployeeId,
          'senderId': request['employeeId'] ?? '',
          'title': 'Leave Request',
          'message':
              'Leave request from ${request['employeeName'] ?? 'Unknown'}',
          'type': 'leave_request',
          'data': request,
          'createdAt': request['createdAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': request['updatedAt'] ?? DateTime.now().toIso8601String(),
          'isRead': true,
        });
        pendingList.add(notification);
      }

      setState(() {
        _pending = pendingList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load leave requests: $e';
      });
    }
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
        title: Text(
          LeaveTranslations.leaveApproval(ref),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.kOnBackground),
            onPressed: () => _loadAllLeaveRequests(forceRefresh: true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: LeaveTranslations.searchByEmployeeLeaveTypeReason(
                      ref,
                    ),
                    hintStyle: TextStyle(
                      color: AppTheme.kOnSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(Icons.search, color: AppTheme.kNanoGold),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppTheme.kOnSurface.withOpacity(0.6),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.kNanoGold,
                labelColor: AppTheme.kNanoGold,
                unselectedLabelColor: AppTheme.kOnSurface.withOpacity(0.6),
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            LeaveTranslations.pending(ref),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pending.isNotEmpty) ...[
                          const SizedBox(width: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.kNanoGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_pending.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Employee Leaves',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaveApprovalContent(_filterLeaveRequests(_pending)),
          _buildEmployeeLeaveListContent(),
        ],
      ),
    );
  }

  Widget _buildEmployeeLeaveListContent() {
    return RefreshIndicator(
      onRefresh: _loadEmployeeLeaves,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingEmployeeLeaves)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
                ),
              ),
            )
          else if (_employeeLeaves.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Processed Leave Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t processed any leave requests yet.\nApprove or reject some requests in the Pending tab to see them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.kOnSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._filterEmployeeLeaves(
              _employeeLeaves,
            ).map((leave) => _buildEmployeeLeaveCard(leave)),
        ],
      ),
    );
  }

  Widget _buildLeaveApprovalContent(List<NotificationModel> leaveRequests) {
    return RefreshIndicator(
      onRefresh: () => _loadAllLeaveRequests(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              child: Text(
                _error!,
                style: TextStyle(color: AppTheme.errorColor),
              ),
            )
          else if (leaveRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _currentTabIndex == 0
                    ? LeaveTranslations.noPendingRequests(ref)
                    : 'No employee leave records found',
                style: TextStyle(color: AppTheme.kOnSurface.withOpacity(0.7)),
              ),
            )
          else
            ...leaveRequests.map((n) => _buildPendingApprovalCard(n)),
        ],
      ),
    );
  }

  Widget _buildEmployeeLeaveCard(Map<String, dynamic> leave) {
    final employeeName =
        leave['employeeName']?.toString() ??
        leave['firstName']?.toString() ??
        leave['name']?.toString() ??
        'Employee ${leave['employeeId']?.toString() ?? 'Unknown'}';

    final employeeId = leave['employeeId']?.toString() ?? '';
    final leaveType = leave['leaveTypeName']?.toString() ?? 'Unknown Type';
    final startDate =
        leave['startDate']?.toString() ??
        leave['fromDate']?.toString() ??
        leave['date']?.toString() ??
        '';
    final endDate =
        leave['endDate']?.toString() ??
        leave['toDate']?.toString() ??
        leave['date']?.toString() ??
        '';

    final totalDays = leave['totalDays']?.toString() ?? '0';
    final reason = leave['reason']?.toString() ?? '';
    final status = leave['status']?.toString() ?? 'pending';
    final statusName = leave['statusName']?.toString() ?? '';
    final positionName =
        leave['positionName']?.toString() ??
        leave['position']?.toString() ??
        '';
    final branchName =
        leave['branchName']?.toString() ?? leave['branch']?.toString() ?? '';

    Color statusColor;
    String statusText;

    if (status.toLowerCase().contains('approved')) {
      statusColor = AppTheme.successColor;
      statusText = statusName.isNotEmpty ? statusName : 'Approved';
    } else if (status.toLowerCase().contains('rejected')) {
      statusColor = AppTheme.errorColor;
      statusText = statusName.isNotEmpty ? statusName : 'Rejected';
    } else {
      statusColor = AppTheme.warningColor;
      statusText = statusName.isNotEmpty ? statusName : 'Pending';
    }

    return Container(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.person, color: AppTheme.kNanoGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${employeeId.isNotEmpty ? employeeId : 'ID: Unknown'} • ${positionName.isNotEmpty ? positionName : 'Position: Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (branchName.isNotEmpty)
                      Text(
                        branchName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note, size: 16, color: AppTheme.kNanoGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leaveType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalDays day${totalDays != '1' ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kNanoGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${startDate.isNotEmpty ? startDate : 'N/A'} - ${endDate.isNotEmpty ? endDate : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(NotificationModel notification) {
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
    final userLevel = _getUserLevel(ref.read(authServiceProvider));
    final isPendingOrSent = statusLower == 'pending' || statusLower == 'sent';
    final isApprovedByManager =
        statusLower == 'approved_manager' ||
        statusLower == 'approved_by_manager' ||
        (statusLower.contains('approved') && statusLower.contains('manager'));

    final isApprovedByTeamLead =
        statusLower == 'approved_team_lead' ||
        statusLower == 'approved_by_team_lead' ||
        (statusLower.contains('approved') && statusLower.contains('team_lead'));

    final isApprovedByHR =
        statusLower == 'approved_hr' || statusLower == 'approved_by_hr';

    final showActions = userLevel == 'hr'
        ? (isPendingOrSent ||
              isApprovedByManager ||
              isApprovedByTeamLead)
        : userLevel == 'approver'
        ? (isPendingOrSent ||
              isApprovedByHR) 
        : userLevel == 'team-lead'
        ? isPendingOrSent 
        : isPendingOrSent; 

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
                      Text(
                        employeeId.isNotEmpty ? employeeId : 'ID: Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                        : statusLower == 'approved_hr' ||
                              statusLower == 'approved_by_hr' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('hr'))
                        ? Colors.purple.withOpacity(0.1)
                        : statusLower == 'approved_team_lead' ||
                              statusLower == 'approved_by_team_lead' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('team_lead'))
                        ? Colors.teal.withOpacity(0.1)
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
                        : statusLower == 'approved_hr' ||
                              statusLower == 'approved_by_hr' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('hr'))
                        ? 'Approved by HR'
                        : statusLower == 'approved_team_lead' ||
                              statusLower == 'approved_by_team_lead' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('team_lead'))
                        ? 'Approved by Team Lead'
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
                          : statusLower == 'approved_hr' ||
                                statusLower == 'approved_by_hr' ||
                                (statusLower.contains('approved') &&
                                    statusLower.contains('hr'))
                          ? Colors.purple[700]
                          : statusLower == 'approved_team_lead' ||
                                statusLower == 'approved_by_team_lead' ||
                                (statusLower.contains('approved') &&
                                    statusLower.contains('team_lead'))
                          ? Colors.teal[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              Container(
                height: 0,
                width: 0,
                child: Builder(
                  builder: (context) {
                    return SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _decide(notification, false, ''),
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
                        onPressed: () => _decide(notification, true, ''),
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

    if (leaveId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No leave ID found')));
      return;
    }

    Map<String, dynamic>? details = _leaveDetails[leaveId];
    if (details == null) {
      final service = LeaveService();
      final res = await service.getLeaveDetails(leaveId);

      if (res['success'] == true) {
        final lr = res['leaveRequest'] ?? res['data'] ?? {};

        // Leave request data processed silently

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
              return <String>[];
            }
          })(),
        };
        _leaveDetails[leaveId] = details;
      }
    }

    if (!mounted) return;

    
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

    
    if (!mounted) return;
    String loadingText = 'Saving...';
    StateSetter? setDialogState;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loadingText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.kOnSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    
    void updateLoadingText(String text) {
      if (mounted && setDialogState != null) {
        loadingText = text;
        setDialogState!(() {});
      }
    }

    try {
      final totalStopwatch = Stopwatch()..start();
      final service = LeaveService();

      final detailsStopwatch = Stopwatch()..start();
      final details = await service.getLeaveDetails(leaveId);
      detailsStopwatch.stop();

      if (details['success'] == true) {
        final currentStatus =
            details['leaveRequest']?['status'] ??
            details['data']?['status'] ??
            details['status'];

        final userLevel = _getUserLevel(auth);
        final statusLower = currentStatus?.toString().toLowerCase() ?? '';

        final isPendingOrSent = statusLower == 'pending' || statusLower == 'sent';
        final isApprovedByManager =
            statusLower == 'approved_manager' ||
            statusLower == 'approved_by_manager' ||
            (statusLower.contains('approved') && statusLower.contains('manager'));
        final isApprovedByTeamLead =
            statusLower == 'approved_team_lead' ||
            statusLower == 'approved_by_team_lead' ||
            (statusLower.contains('approved') &&
                statusLower.contains('team_lead'));
        final isApprovedByHR =
            statusLower == 'approved_hr' ||
            statusLower == 'approved_by_hr' ||
            (statusLower.contains('approved') && statusLower.contains('hr'));

        final canAct = userLevel == 'hr'
            ? (isPendingOrSent ||
                  isApprovedByManager ||
                  isApprovedByTeamLead) 
            : userLevel == 'approver'
            ? (isPendingOrSent ||
                  isApprovedByHR) 
            : isPendingOrSent; 

        if (currentStatus != null && !canAct) {
          if (mounted) Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This request is already $currentStatus. Refreshing list.',
              ),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          await _loadAllLeaveRequests();
          return;
        }
      }

      final approvalStopwatch = Stopwatch()..start();
      final status = approve ? 'approved' : 'rejected';
      final userRole = _getUserLevel(auth);
      final res = await service.updateLeaveStatus(
        leaveId: leaveId,
        status: status,
        approverId: approverId,
        userRole: userRole,
        note: note,
      );
      approvalStopwatch.stop();

      if (res['success'] == true) {
        final leaveId =
            notification.data['leaveRequestId'] ??
            notification.data['leaveId'] ??
            notification.data['id'] ??
            '';

        if (leaveId.isNotEmpty) {
          final processedRequest = Map<String, dynamic>.from(notification.data);
          processedRequest['status'] = approve ? 'approved' : 'rejected';
          processedRequest['approvedBy'] = approve ? approverId : null;
          processedRequest['rejectedBy'] = !approve ? approverId : null;
          processedRequest['updatedAt'] = DateTime.now().toIso8601String();

          _processedRequests[leaveId] = processedRequest;
        }

        totalStopwatch.stop();

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
              title: Text(
                approve ? 'Approved!' : 'Rejected!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kOnSurface,
                ),
              ),
              content: Text(
                approve
                    ? 'Leave request approved successfully!'
                    : 'Leave request rejected.',
                style: TextStyle(color: AppTheme.kOnSurface),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppTheme.kNanoGold),
                  ),
                ),
              ],
            ),
          );
        }
        
        LeaveController.clearAllCache();
        ref.invalidate(leaveControllerProvider(approverId));
        _loadAllLeaveRequests(showLoading: false);
        _loadEmployeeLeaves(showLoading: false);
      } else {
        final alt = await service.approveOrRejectLeave(
          leaveId: leaveId,
          action: approve ? 'approve' : 'reject',
          approverId: approverId,
          userRole: userRole,
          note: note,
        );
        
        if (alt['success'] == true) {
          if (leaveId.isNotEmpty) {
            final processedRequest = Map<String, dynamic>.from(notification.data);
            processedRequest['status'] = approve ? 'approved' : 'rejected';
            processedRequest['approvedBy'] = approve ? approverId : null;
            processedRequest['rejectedBy'] = !approve ? approverId : null;
            processedRequest['updatedAt'] = DateTime.now().toIso8601String();

            _processedRequests[leaveId] = processedRequest;
          }

          if (mounted) Navigator.of(context).pop();

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 48,
                ),
                title: Text(
                  approve ? 'Approved!' : 'Rejected!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kOnSurface,
                  ),
                ),
                content: Text(
                  approve
                      ? 'Leave request approved successfully!'
                      : 'Leave request rejected.',
                  style: TextStyle(color: AppTheme.kOnSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(color: AppTheme.kNanoGold),
                    ),
                  ),
              ],
            ),
          );
        }
        
        LeaveController.clearAllCache();
        ref.invalidate(leaveControllerProvider(approverId));
        _loadAllLeaveRequests(showLoading: false);
        _loadEmployeeLeaves(showLoading: false);
        } else {
              if (mounted) Navigator.of(context).pop();
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: Icon(
                  Icons.error,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
                title: Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kOnSurface,
                  ),
                ),
                content: Text(
                  alt['message'] ?? res['message'] ?? 'Failed to update leave',
                  style: TextStyle(color: AppTheme.kOnSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(color: AppTheme.kNanoGold),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.error,
              color: AppTheme.errorColor,
              size: 48,
            ),
            title: Text(
              'Error',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.kOnSurface,
              ),
            ),
            content: Text(
              'An error occurred: ${e.toString()}',
              style: TextStyle(color: AppTheme.kOnSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(color: AppTheme.kNanoGold),
                ),
              ),
            ],
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
