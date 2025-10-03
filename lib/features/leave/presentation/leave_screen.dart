import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../data/leave_repository.dart';
import '../data/leave_model.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  // Check if the current user can approve leave requests (HR, Manager, Approver)
  bool _canApproveLeave() {
    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;
    final position = authService.currentPositionName ?? '';

    if (currentEmployeeId == null) return false;

    final positionLower = position.toLowerCase();

    if (positionLower.contains('hr') ||
        positionLower.contains('human resource')) {
      return true;
    }

    // Managers can approve
    if (positionLower.contains('manager') ||
        positionLower.contains('supervisor') ||
        positionLower.contains('lead')) {
      return true;
    }

    // Approvers can approve
    if (positionLower.contains('approver') ||
        positionLower.contains('management')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = currentEmployeeId;
    final leaveAsync = ref.watch(leaveControllerProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: leaveAsync.when(
        data: (leaveVm) => _buildLeaveContent(context, leaveVm),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Error loading leave data',
                style: TextStyle(fontSize: 18, color: AppTheme.kOnBackground),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveContent(BuildContext context, LeaveVm leaveVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewLeaveListButton(context),
          const SizedBox(height: 24),
          if (_canApproveLeave()) ...[
            _buildManagerSection(context), // Show for HR/Managers/Approvers
            const SizedBox(height: 24),
          ],
          _buildLeaveTypesList(context, leaveVm.balance),
          const SizedBox(height: 24),
          _buildRecentRequests(leaveVm.requests),
        ],
      ),
    );
  }

  Widget _buildViewLeaveListButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToLeaveList(context),
        icon: Icon(Icons.list_alt, color: AppTheme.kNanoWhite),
        label: Text(
          'View Leave List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kNanoWhite,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.kNanoGold,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppTheme.kNanoGold.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildManagerSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kNanoGold.withOpacity(0.1),
            AppTheme.kNanoGoldDark.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.kNanoGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
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
                      'Team Leave Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kOnBackground,
                      ),
                    ),
                    Text(
                      'Approve and manage your team\'s leave requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/leave/approval'),
              icon: const Icon(Icons.approval),
              label: const Text('Team Leave Approvals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kNanoGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypesList(BuildContext context, LeaveBalance balance) {
    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'User not logged in',
          style: TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    if (balance.balances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load leave balance',
          style: TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Types',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 16),
        ...balance.balances.map(
          (leaveTypeBalance) => _buildLeaveTypeCard(context, leaveTypeBalance),
        ),
      ],
    );
  }

  // Helper method to get color for leave type
  Color _getLeaveTypeColor(String leaveTypeName) {
    final name = leaveTypeName.toLowerCase();

    if (name.contains('annual')) {
      return AppTheme.primaryColor;
    } else if (name.contains('ป่วย') || name.contains('sick')) {
      return AppTheme.errorColor;
    } else if (name.contains('ไม่ได้รับค่าจ้าง') || name.contains('unpaid')) {
      return AppTheme.secondaryColor;
    } else if (name.contains('ลากิจ')) {
      return const Color(0xFF9C27B0);
    } else if (name.contains('สมรส') || name.contains('marriage')) {
      return const Color(0xFF607D8B);
    } else if (name.contains('ทำหมัน') || name.contains('sterilization')) {
      return const Color(0xFF795548);
    } else if (name.contains('ทหาร') || name.contains('military')) {
      return const Color(0xFFFF5722);
    } else if (name.contains('ฌาปนกิจ') || name.contains('funeral')) {
      return const Color(0xFFFF5722);
    } else {
      return AppTheme.kNanoGold;
    }
  }

  // Helper method to get icon for leave type
  IconData _getLeaveTypeIcon(String leaveTypeName) {
    final name = leaveTypeName.toLowerCase();

    if (name.contains('annual')) {
      return Icons.beach_access;
    } else if (name.contains('ป่วย') || name.contains('sick')) {
      return Icons.health_and_safety;
    } else if (name.contains('ไม่ได้รับค่าจ้าง') || name.contains('unpaid')) {
      return Icons.event_available;
    } else if (name.contains('ลากิจ')) {
      return Icons.calendar_today;
    } else if (name.contains('สมรส') || name.contains('marriage')) {
      return Icons.favorite;
    } else if (name.contains('ทำหมัน') || name.contains('sterilization')) {
      return Icons.medical_services;
    } else if (name.contains('ทหาร') || name.contains('military')) {
      return Icons.military_tech;
    } else if (name.contains('ฌาปนกิจ') || name.contains('funeral')) {
      return Icons.emergency;
    } else {
      return Icons.event_note;
    }
  }

  // Helper method to get icon and color for leave type (legacy)
  (IconData, Color) _getLeaveTypeIconAndColor(
    String thaiName,
    String englishName,
  ) {
    final name = englishName.toLowerCase();

    if (name.contains('annual') || name.contains('vacation')) {
      return (Icons.beach_access, AppTheme.primaryColor);
    } else if (name.contains('sick')) {
      return (Icons.health_and_safety, AppTheme.errorColor);
    } else if (name.contains('unpaid')) {
      return (Icons.event_available, AppTheme.secondaryColor);
    } else if (name.contains('maternity')) {
      return (Icons.child_care, const Color(0xFFE91E63));
    } else if (name.contains('personal')) {
      return (Icons.family_restroom, const Color(0xFF9C27B0));
    } else if (name.contains('funeral')) {
      return (Icons.emergency, const Color(0xFFFF5722));
    } else if (name.contains('marriage')) {
      return (Icons.favorite, const Color(0xFF607D8B));
    } else if (name.contains('sterilization')) {
      return (Icons.medical_services, const Color(0xFF795548));
    } else {
      // Default fallback
      return (Icons.event_note, AppTheme.kNanoGold);
    }
  }

  // Helper method to calculate remaining days for each leave type
  double _getRemainingDaysForType(
    String thaiName,
    String englishName,
    LeaveBalance balance,
    int maxDays,
  ) {
    final name = englishName.toLowerCase();

    if (name.contains('annual') || name.contains('vacation')) {
      return balance.annualLeave.toDouble();
    } else if (name.contains('sick')) {
      return balance.sickLeave.toDouble();
    } else if (name.contains('unpaid')) {
      return balance.personalLeave.toDouble();
    } else {
      // For other types (maternity, personal, funeral, etc.), show full available days
      return maxDays.toDouble();
    }
  }

  Widget _buildLeaveTypeCard(BuildContext context, LeaveTypeBalance leaveTypeBalance) {
    final isAvailable = leaveTypeBalance.remaining > 0 && leaveTypeBalance.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable
              ? () => _navigateToLeaveRequest(
                  context,
                  leaveTypeBalance.leaveTypeId,
                  leaveTypeBalance.leaveTypeName,
                  leaveTypeBalance.totalAllocated,
                )
              : null,
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? AppTheme.kNanoGold.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLeaveTypeColor(leaveTypeBalance.leaveTypeName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getLeaveTypeIcon(leaveTypeBalance.leaveTypeName),
                  color: isAvailable 
                      ? _getLeaveTypeColor(leaveTypeBalance.leaveTypeName) 
                      : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaveTypeBalance.leaveTypeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? AppTheme.kOnSurface
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${leaveTypeBalance.used} / ${leaveTypeBalance.totalAllocated} days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.kOnSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (leaveTypeBalance.percentageUsed > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.kNanoGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${leaveTypeBalance.percentageUsed}% used',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.kNanoGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: leaveTypeBalance.percentageUsed / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _getLeaveTypeColor(leaveTypeBalance.leaveTypeName),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.kNanoGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kNanoGold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Used Up',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeCardOld(BuildContext context, LeaveTypeData leaveType) {
    final progress = leaveType.remainingDays / leaveType.totalDays;
    final isAvailable = leaveType.remainingDays > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable
              ? () => _navigateToLeaveRequest(
                  context,
                  leaveType.type,
                  leaveType.name,
                  leaveType.totalDays,
                )
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAvailable
                    ? leaveType.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: leaveType.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    leaveType.icon,
                    color: isAvailable ? leaveType.color : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaveType.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? AppTheme.kOnSurface
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${leaveType.remainingDays.toStringAsFixed(0)} / ${leaveType.totalDays} days',
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable
                                  ? AppTheme.kOnSurface.withOpacity(0.7)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAvailable ? leaveType.color : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusButton(leaveType, isAvailable),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(LeaveTypeData leaveType, bool isAvailable) {
    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Exhausted',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: leaveType.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: leaveType.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        'Available',
        style: TextStyle(
          fontSize: 12,
          color: leaveType.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecentRequests(List<LeaveRequest> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No leave requests yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...requests.take(3).map((request) => _buildRequestCard(request)),
      ],
    );
  }

  // Normalize status for employee view - show simple statuses only
  String _normalizeStatusForEmployee(String status) {
    final statusLower = status.toLowerCase();

    // If already final status, return as is
    if (statusLower == 'approved' || statusLower == 'rejected') {
      return statusLower;
    }

    // If rejected, return rejected
    if (statusLower.contains('rejected')) {
      return 'rejected';
    }

    // If approved (any level), return approved
    if (statusLower.contains('approved')) {
      return 'approved';
    }

    // Everything else is pending
    return 'pending';
  }

  Widget _buildRequestCard(LeaveRequest request) {
    final normalizedStatus = _normalizeStatusForEmployee(request.status);
    Color statusColor;
    IconData statusIcon;

    switch (normalizedStatus) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
      default: // pending
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.kOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.start?.day ?? 'N/A'}/${request.start?.month ?? 'N/A'} - ${request.end?.day ?? 'N/A'}/${request.end?.month ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.kOnSurface.withOpacity(0.7),
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
              request.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLeaveRequest(
    BuildContext context,
    String leaveTypeId,
    String leaveTypeName,
    int maxDays,
  ) {
    // Pass leave type ID, name, and max days as query parameters
    context.push(
      '/leave/request/$leaveTypeId?name=${Uri.encodeComponent(leaveTypeName)}&maxDays=$maxDays',
    );
  }

  void _navigateToLeaveList(BuildContext context) {
    context.push('/leave/list');
  }
}

class LeaveTypeData {
  final String type;
  final String name;
  final IconData icon;
  final int totalDays;
  final double remainingDays;
  final Color color;

  LeaveTypeData({
    required this.type,
    required this.name,
    required this.icon,
    required this.totalDays,
    required this.remainingDays,
    required this.color,
  });
}
