import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/language_provider.dart';
import '../data/leave_repository.dart';
import '../data/leave_model.dart';
import '../utils/leave_translations.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  bool _canApproveLeave() {
    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;
    final position = authService.currentPositionName ?? '';
    print('position: $position');

    if (currentEmployeeId == null) return false;

    final positionLower = position.toLowerCase();

    // HR can see Team Leave Management
    if (positionLower.contains('hr') ||
        positionLower.contains('human resource')) {
      return true;
    }

    // Approver/Management can see Team Leave Management
    if (positionLower.contains('approver') ||
        positionLower.contains('management')) {
      return true;
    }

    // Manager can see Team Leave Management
    if (positionLower.contains('manager') ||
        positionLower.contains('supervisor')) {
      return true;
    }

    // Programmer (Team Lead) can see Team Leave Management
    // Handles both "Programmer (Team Lead)" and "nano-store-office-programmer-team-lead" formats
    if (positionLower.contains('programmer (team lead)') || positionLower.contains('nano-store-office-programmer-team-lead')) {
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
        title: Text(
          LeaveTranslations.leaveManagement(ref),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = currentEmployeeId;
          LeaveController.clearCache(userId);
          ref.refresh(leaveControllerProvider(userId));
        },
        child: leaveAsync.when(
          data: (leaveVm) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildLeaveContent(context, leaveVm),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LeaveTranslations.errorLoadingLeaveData(ref),
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.kOnBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = currentEmployeeId;
                      LeaveController.clearCache(userId);
                      ref.refresh(leaveControllerProvider(userId));
                    },
                    child: Text(LeaveTranslations.retry(ref)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveContent(BuildContext context, LeaveVm leaveVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewLeaveListButton(context),
          const SizedBox(height: 24),
          if (_canApproveLeave()) ...[
            _buildManagerSection(context), 
            const SizedBox(height: 24),
          ],
          _buildLeaveTypesList(context, leaveVm.balance),
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
          LeaveTranslations.viewLeaveList(ref),
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
                      LeaveTranslations.teamLeaveManagement(ref),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kOnBackground,
                      ),
                    ),
                    Text(
                      LeaveTranslations.approveAndManageTeam(ref),
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
              label: Text(LeaveTranslations.teamLeaveApprovals(ref)),
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
          LeaveTranslations.userNotLoggedIn(ref),
          style: TextStyle(color: AppTheme.errorColor),
        ),
      );
    }

    if (balance.balances.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                LeaveTranslations.noDataAvailable(ref),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                LeaveTranslations.failedToLoadLeaveBalance(ref),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LeaveTranslations.leaveTypes(ref),
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

  Color _getLeaveTypeColor(String leaveTypeName) {
    final name = leaveTypeName.toLowerCase();

    if (name.contains('พักร้อน') || name.contains('annual')) {
      return const Color(0xFF2196F3); // Blue
    } 
    else if (name.contains('ป่วย') || name.contains('sick')) {
      return const Color(0xFFF44336); // Red
    } 
    else if (name.contains('ไม่ได้รับค่าจ้าง') || name.contains('unpaid') || name.contains('without pay')) {
      return const Color(0xFF9E9E9E); // Gray
    } 
    else if (name.contains('สมรส') || name.contains('marriage')) {
      return const Color(0xFFE91E63); // Pink
    } 
    else if (name.contains('ลาคลอด') || name.contains('maternity')) {
      return const Color(0xFF9C27B0); // Purple
    } 
    else if (name.contains('ภรรยาคลอด') || name.contains('paternity')) {
      return const Color(0xFF607D8B); // Blue-gray
    } 
    else if (name.contains('ฌาปนกิจ') || name.contains('funeral') || name.contains('compassionate')) {
      return const Color(0xFF424242); // Dark gray
    } 
    else if (name.contains('ทหาร') || name.contains('military')) {
      return const Color(0xFF689F38); // Olive green
    } 
    else if (name.contains('ทำหมัน') || name.contains('sterilization')) {
      return const Color(0xFF009688); // Teal
    } 
    else if (name.contains('ธุรกิจ') || name.contains('business')) {
      return const Color(0xFFFF9800); // Orange
    } 
    else {
      return AppTheme.kNanoGold;
    }
  }

  IconData _getLeaveTypeIcon(String leaveTypeName) {
    final name = leaveTypeName.toLowerCase();

    if (name.contains('พักร้อน') || name.contains('annual')) {
      return Icons.beach_access;
    } 
    else if (name.contains('ป่วย') || name.contains('sick')) {
      return Icons.local_hospital;
    } 
    else if (name.contains('ไม่ได้รับค่าจ้าง') || name.contains('unpaid') || name.contains('without pay')) {
      return Icons.money_off;
    } 
    else if (name.contains('สมรส') || name.contains('marriage')) {
      return Icons.favorite;
    } 
    else if (name.contains('ลาคลอด') || name.contains('maternity')) {
      return Icons.pregnant_woman;
    }     
    else if (name.contains('ภรรยาคลอด') || name.contains('paternity')) {
      return Icons.family_restroom;
    } 
    else if (name.contains('ฌาปนกิจ') || name.contains('funeral') || name.contains('compassionate') || name.contains('ร่วมงานศพ')) {
      return Icons.local_florist;
    } 
    else if (name.contains('ทหาร') || name.contains('military')) {
      return Icons.military_tech;
    } 
    else if (name.contains('ทำหมัน') || name.contains('sterilization')) {
      return Icons.medical_services;
    } 
    else if (name.contains('ธุรกิจ') || name.contains('business')) {
      return Icons.business_center;
    } 
    else {
      return Icons.event_note;
    }
  }

  Widget _buildLeaveTypeCard(
    BuildContext context,
    LeaveTypeBalance leaveTypeBalance,
  ) {
    final isAvailable =
        leaveTypeBalance.remaining > 0 && leaveTypeBalance.isActive;

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
                    leaveTypeNameEng: leaveTypeBalance.leaveTypeNameEng ??
                        leaveTypeBalance.leaveTypeName,
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
                    color: _getLeaveTypeColor(
                      leaveTypeBalance.leaveTypeName,
                    ).withOpacity(0.1),
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
                        leaveTypeBalance.getLocalizedName(
                          ref.watch(languageProvider),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? AppTheme.kOnSurface
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${leaveTypeBalance.used} / ${leaveTypeBalance.totalAllocated} ${LeaveTranslations.days(ref)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                              color: _getLeaveTypeColor(
                                leaveTypeBalance.leaveTypeName,
                              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kNanoGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      LeaveTranslations.available(ref),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kNanoGold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      LeaveTranslations.usedUp(ref),
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

  // Widget _buildRecentRequests(List<LeaveRequest> requests) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         LeaveTranslations.recentRequests(ref),
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: AppTheme.kOnBackground,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       if (requests.isEmpty)
  //         Container(
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             color: AppTheme.kSurface,
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: Colors.grey.withOpacity(0.2)),
  //           ),
  //           child: Column(
  //             children: [
  //               Icon(
  //                 Icons.inbox_outlined,
  //                 size: 48,
  //                 color: Colors.grey.withOpacity(0.5),
  //               ),
  //               const SizedBox(height: 12),
  //               Text(
  //                 LeaveTranslations.noLeaveRequests(ref),
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   color: Colors.grey.withOpacity(0.7),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )
  //       else
  //         ...requests.take(3).map((request) => _buildRequestCard(request)),
  //     ],
  //   );
  // }

  String _normalizeStatusForEmployee(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower == 'approved' || statusLower == 'rejected') {
      return statusLower;
    }

    if (statusLower.contains('rejected')) {
      return 'rejected';
    }

    if (statusLower.contains('approved')) {
      return 'approved';
    }

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
              LeaveTranslations.translateStatus(
                ref,
                request.status,
              ).toUpperCase(),
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
    int maxDays, {
    String? leaveTypeNameEng,
  }) {
    final buffer = StringBuffer(
      '/leave/request/$leaveTypeId'
      '?name=${Uri.encodeComponent(leaveTypeName)}'
      '&maxDays=$maxDays',
    );

    if (leaveTypeNameEng != null && leaveTypeNameEng.isNotEmpty) {
      buffer.write(
        '&engName=${Uri.encodeComponent(leaveTypeNameEng)}',
      );
    }

    context.push(buffer.toString());
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
