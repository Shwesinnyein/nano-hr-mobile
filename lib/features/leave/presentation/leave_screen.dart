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

  Widget _buildLeaveTypesList(BuildContext context, LeaveBalance balance) {
    final leaveTypes = [
      LeaveTypeData(
        type: 'vacation',
        name: 'ลาพักร้อน (Annual Leave)',
        icon: Icons.beach_access,
        totalDays: 6,
        remainingDays: balance.annualLeave.toDouble(),
        color: AppTheme.primaryColor,
      ),
      LeaveTypeData(
        type: 'sick',
        name: 'ลาป่วย(ได้รับค่าจ้าง) (Paid Sick Leave)',
        icon: Icons.health_and_safety,
        totalDays: 30,
        remainingDays: balance.sickLeave.toDouble(),
        color: AppTheme.errorColor,
      ),
      LeaveTypeData(
        type: 'unpaid',
        name: 'ลา(โดยไม่ได้รับค่าจ้าง) (Unpaid Leave)',
        icon: Icons.event_available,
        totalDays: 30,
        remainingDays: balance.personalLeave.toDouble(),
        color: AppTheme.secondaryColor,
      ),
      LeaveTypeData(
        type: 'maternity',
        name: 'ลาคลอด (Maternity Leave)',
        icon: Icons.child_care,
        totalDays: 98,
        remainingDays: 98.0, // Available days
        color: const Color(0xFFE91E63), // Pink
      ),
      LeaveTypeData(
        type: 'personal',
        name: 'ลากิจ(ได้รับค่าจ้าง) (Paid Personal Leave)',
        icon: Icons.family_restroom,
        totalDays: 3,
        remainingDays: 3.0, // Available days
        color: const Color(0xFF9C27B0), // Purple
      ),
      LeaveTypeData(
        type: 'funeral',
        name: 'ลา(เพื่อจัดงานฌาปนกิจ) (Funeral Leave)',
        icon: Icons.emergency,
        totalDays: 3,
        remainingDays: 3.0, // Available days
        color: const Color(0xFFFF5722), // Deep Orange
      ),
      LeaveTypeData(
        type: 'marriage',
        name: 'ลาสมรส (Marriage Leave)',
        icon: Icons.favorite,
        totalDays: 3,
        remainingDays: 3.0, // 3 days, 0 hours remaining
        color: const Color(0xFF607D8B), // Blue Grey
      ),
      LeaveTypeData(
        type: 'sterilization',
        name: 'ลา(เพื่อทำหมัน) (Sterilization Leave)',
        icon: Icons.medical_services,
        totalDays: 3,
        remainingDays: 3.0, // 3 days, 0 hours remaining
        color: const Color(0xFF795548), // Brown
      ),
    ];

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
        ...leaveTypes.map(
          (leaveType) => _buildLeaveTypeCard(context, leaveType),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeCard(BuildContext context, LeaveTypeData leaveType) {
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
              ? () => _navigateToLeaveRequest(context, leaveType.type)
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

  Widget _buildRequestCard(LeaveRequest request) {
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

  void _navigateToLeaveRequest(BuildContext context, String leaveType) {
    context.push('/leave/request/$leaveType');
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
