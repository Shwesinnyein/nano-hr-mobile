import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../../../core/services/auth_service.dart';
import '../data/leave_repository.dart';
import '../data/leave_model.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Refresh the leave list data when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;
    if (currentEmployeeId != null) {
      // Force refresh and show loading state
      ref.invalidate(employeeLeaveListProvider(currentEmployeeId));
    }

    // Add a small delay to ensure loading state is visible
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final employeeId = currentEmployeeId;
    final leaveAsync = ref.watch(employeeLeaveListProvider(employeeId));

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text(
          'Leave List',
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
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isRefreshing
          ? _buildSkeletonLoading()
          : leaveAsync.when(
              data: (leaveRequests) => RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildLeaveList(leaveRequests),
              ),
              loading: () => _buildSkeletonLoading(),
              error: (error, stack) => ErrorStateWidget(
                message: 'Failed to load leave requests. Please try again.',
                actionText: 'Retry',
                onAction: _refreshData,
              ),
            ),
    );
  }

  Widget _buildSettingsSkeleton() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoading(height: 20, width: 150),
          const SizedBox(height: 12),
          Row(
            children: [
              const SkeletonLoading(height: 16, width: 100),
              const SizedBox(width: 8),
              const SkeletonLoading(height: 16, width: 80),
            ],
          ),
          const SizedBox(height: 8),
          const SkeletonLoading(height: 16, width: 120),
        ],
      ),
    );
  }

  Widget _buildLeaveSettingsCard(LeaveSettingsResponse settings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppTheme.kNanoWhite, size: 24),
              const SizedBox(width: 8),
              Text(
                'Leave Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kNanoWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.kNanoWhite.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSettingsItem('Available', settings.count, Icons.list),
              _buildSettingsItem(
                'Eligible',
                settings.employeeEligible ? 'Yes' : 'No',
                Icons.check_circle,
              ),
              _buildSettingsItem(
                'Months',
                '${settings.monthsWithCompany}/${settings.requiredMonths}',
                Icons.calendar_month,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Available Leave Types:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.kNanoWhite,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.data
                .take(4)
                .map(
                  (setting) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kNanoWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      setting.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kNanoWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (settings.data.length > 4) ...[
            const SizedBox(height: 8),
            Text(
              '+${settings.data.length - 4} more types',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.kNanoWhite.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.kNanoWhite, size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.kNanoWhite,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.kNanoWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return AnimatedFadeIn(
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonLoading(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoading(height: 16, width: 120),
                          const SizedBox(height: 4),
                          const SkeletonLoading(height: 14, width: 80),
                        ],
                      ),
                    ),
                    const SkeletonLoading(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonLoading(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonLoading(height: 14, width: 200),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveList(List<LeaveRequest> requests) {
    print(
      '🔍 LeaveListScreen: Building leave list with ${requests.length} requests',
    );
    for (int i = 0; i < requests.length; i++) {
      print(
        '🔍 LeaveListScreen: Request $i: ${requests[i].leaveType} - ${requests[i].reason}',
      );
    }

    return Column(
      children: [
        // Show message when no leave requests are available
        if (requests.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Leave Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You haven\'t submitted any leave requests yet.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        // Show leave requests if available
        if (requests.isNotEmpty) ...[
          _buildSummaryCard(requests),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return AnimatedFadeIn(
                  delay: Duration(milliseconds: index * 50),
                  child: GestureDetector(
                    onTap: () => _showLeaveDetailsDialog(context, request),
                    child: _buildLeaveRequestCard(request),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(List<LeaveRequest> requests) {
    final totalRequests = requests.length;
    final approvedRequests = requests
        .where((r) => r.status == 'approved')
        .length;
    final pendingRequests = requests.where((r) => r.status == 'pending').length;
    final rejectedRequests = requests
        .where((r) => r.status == 'rejected')
        .length;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppTheme.kNanoWhite, size: 24),
              const SizedBox(width: 8),
              Text(
                'Leave Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kNanoWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', totalRequests, Icons.calendar_today),
              _buildSummaryItem(
                'Approved',
                approvedRequests,
                Icons.check_circle,
              ),
              _buildSummaryItem('Pending', pendingRequests, Icons.pending),
              _buildSummaryItem('Rejected', rejectedRequests, Icons.cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.kNanoWhite, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kNanoWhite,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.kNanoWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
    }

    // Calculate duration based on request type
    String durationText;
    if (request.startTime != null && request.endTime != null) {
      durationText = '${request.startTime} - ${request.endTime}';
    } else if (request.startDate != null && request.endDate != null) {
      final startDate = DateTime.parse(request.startDate!);
      final endDate = DateTime.parse(request.endDate!);
      final daysDifference = endDate.difference(startDate).inDays + 1;
      durationText = '$daysDifference day${daysDifference > 1 ? 's' : ''}';
    } else {
      durationText = 'N/A';
    }

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
            border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with leave type and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getLeaveTypeColor(
                        request.leaveType,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLeaveTypeIcon(request.leaveType),
                      color: _getLeaveTypeColor(request.leaveType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeFirst(request.leaveType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          durationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.kOnSurface.withOpacity(0.7),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date/Time information based on leave type
              if (request.requestType == 'daily') ...[
                // Daily leave: Show From Date - To Date
                if (request.startDate != null && request.endDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${_formatDate(DateTime.parse(request.startDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'To: ${_formatDate(DateTime.parse(request.endDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ] else if (request.fromDate != null &&
                    request.toDate != null) ...[
                  // Fallback to fromDate/toDate if startDate/endDate not available
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${_formatDate(DateTime.parse(request.fromDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'To: ${_formatDate(DateTime.parse(request.toDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Date information not available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else if (request.requestType == 'hourly' &&
                  request.date != null) ...[
                // Hourly leave: Show Date and Start Time - End Time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${_formatDate(DateTime.parse(request.date!))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                if (request.startTime != null && request.endTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${request.startTime} - ${request.endTime}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Fallback for other cases
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],

              // Total days for daily leave
              if (request.requestType == 'daily' &&
                  request.totalDays != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Total Days: ${request.totalDays}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],

              // Reason
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Attachment
              if (request.attachmentUrl != null &&
                  request.attachmentUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openAttachment(request.attachmentUrl!),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppTheme.kNanoGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attachment: ${request.attachmentUrl!.split('/').last}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.kNanoGold,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.download, size: 14, color: AppTheme.kNanoGold),
                    ],
                  ),
                ),
              ],

              // Created date
              ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${request.createdAt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kOnSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'annual':
        return AppTheme.primaryColor;
      case 'sick':
        return AppTheme.errorColor;
      case 'casual':
        return AppTheme.secondaryColor;
      case 'maternity':
        return const Color(0xFFE91E63);
      case 'paternity':
        return const Color(0xFF9C27B0);
      case 'emergency':
        return const Color(0xFFFF5722);
      case 'study':
        return const Color(0xFF607D8B);
      case 'compensatory':
        return const Color(0xFF795548);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'annual':
        return Icons.beach_access;
      case 'sick':
        return Icons.health_and_safety;
      case 'casual':
        return Icons.event_available;
      case 'maternity':
        return Icons.child_care;
      case 'paternity':
        return Icons.family_restroom;
      case 'emergency':
        return Icons.emergency;
      case 'study':
        return Icons.school;
      case 'compensatory':
        return Icons.work_off;
      default:
        return Icons.calendar_today;
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, LeaveRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getLeaveTypeColor(
                              request.leaveType,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getLeaveTypeIcon(request.leaveType),
                            color: _getLeaveTypeColor(request.leaveType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalizeFirst(request.leaveType),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.kOnSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    request.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  request.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(request.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Leave Details
                    _buildDetailRow(
                      'Request Type',
                      request.requestType?.toUpperCase() ?? 'N/A',
                      Icons.category,
                    ),

                    if (request.requestType == 'daily') ...[
                      _buildDetailRow(
                        'From Date',
                        request.fromDate ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      _buildDetailRow(
                        'To Date',
                        request.toDate ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      if (request.totalDays != null)
                        _buildDetailRow(
                          'Total Days',
                          '${request.totalDays}',
                          Icons.calendar_view_week,
                        ),
                    ],

                    if (request.requestType == 'hourly') ...[
                      _buildDetailRow(
                        'Date',
                        request.date ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      if (request.workingShift != null)
                        _buildDetailRow(
                          'Working Shift',
                          request.workingShift!,
                          Icons.access_time,
                        ),
                      if (request.startTime != null && request.endTime != null)
                        _buildDetailRow(
                          'Time',
                          '${request.startTime} - ${request.endTime}',
                          Icons.schedule,
                        ),
                    ],

                    _buildDetailRow(
                      'Reason',
                      request.reason.isNotEmpty
                          ? request.reason
                          : 'No reason provided',
                      Icons.note,
                      isMultiline: true,
                    ),

                    if (request.attachmentUrl != null &&
                        request.attachmentUrl!.isNotEmpty)
                      _buildAttachmentRow(request.attachmentUrl!),

                    _buildDetailRow(
                      'Created',
                      request.createdAt,
                      Icons.schedule,
                    ),

                    _buildDetailRow(
                      'Last Updated',
                      request.updatedAt,
                      Icons.update,
                    ),

                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kNanoGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.kOnSurface,
                  ),
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }

  Widget _buildAttachmentRow(String attachmentUrl) {
    final fileName = attachmentUrl.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    IconData attachmentIcon;
    Color attachmentColor;

    // Determine icon and color based on file type
    switch (fileExtension) {
      case 'pdf':
        attachmentIcon = Icons.picture_as_pdf;
        attachmentColor = Colors.red;
      case 'doc':
      case 'docx':
        attachmentIcon = Icons.description;
        attachmentColor = Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        attachmentIcon = Icons.image;
        attachmentColor = Colors.green;
      case 'xls':
      case 'xlsx':
        attachmentIcon = Icons.table_chart;
        attachmentColor = Colors.green;
      case 'txt':
        attachmentIcon = Icons.text_snippet;
        attachmentColor = Colors.grey;
      default:
        attachmentIcon = Icons.attach_file;
        attachmentColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attachmentIcon, size: 20, color: attachmentColor),
              const SizedBox(width: 12),
              Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openAttachment(attachmentUrl),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: attachmentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: attachmentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(attachmentIcon, color: attachmentColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.kOnSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view/download',
                          style: TextStyle(
                            fontSize: 12,
                            color: attachmentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.download, color: attachmentColor, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open attachment');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening attachment: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    // This would need to be called from a context that has ScaffoldMessenger
    // For now, we'll just print the error
  }
}
