import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
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
    final positionLower = position.toLowerCase();

    if (positionLower.contains('hr') ||
        positionLower.contains('human resource')) {
      return 'hr';
    }

    if (positionLower.contains('approver') ||
        positionLower.contains('management')) {
      return 'approver';
    }

    // Check for warehouse manager before general manager check
    if (positionLower.contains('warehouse manager')) {
      return 'warehouse-manager';
    }

    if (positionLower.contains('manager')) {
      return 'manager';
    }

    // Check for team lead positions - handle both formats
    if (positionLower.contains('programmer team lead') ||
        positionLower.contains('programmer (team lead)') ||
        positionLower.contains('nano-store-office-programmer-team-lead') || 
        positionLower.contains('nano-vip-programmer-team-lead')) {
      return 'team-lead';
    }

    return 'employee';
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

  Widget _buildApprovalSteps(Map<String, dynamic> details, String statusLower) {
    final workflow = details['approvalWorkflow']?.toString() ?? '';
    final companyName = (details['companyName'] ?? '').toString().toLowerCase();
    final positionName = (details['positionName'] ?? '').toString().toLowerCase();
    final isNanoVip = companyName.contains('nano-vip') || companyName.contains('nanovip');
    final approvalHistory = (details['approvalHistory'] as List<dynamic>?) ?? [];
    
    // Create a map of level -> approval entry for quick lookup
    final Map<String, Map<String, dynamic>> approvalMap = {};
    for (final entry in approvalHistory) {
      if (entry is Map<String, dynamic>) {
        final level = (entry['level'] ?? '').toString().toLowerCase();
        if (level.isNotEmpty) {
          approvalMap[level] = entry;
        }
      }
    }
    
    // Determine steps based on position and company
    List<String> allSteps = [];
    
    // Check if requester is HR
    final isHR = positionName.contains('hr') || 
                 positionName.contains('human resource') ||
                 positionName.contains('human resources');
    
    // Check if requester is Programmer/Developer
    final isProgrammer = positionName.contains('programmer') || 
                         positionName.contains('developer') ||
                         positionName.contains('software engineer');
    
    // Check if requester is Programmer Team Lead
    final isProgrammerTeamLead = isProgrammer && 
                                 (positionName.contains('team lead') || 
                                  positionName.contains('programmer (team lead)') ||
                                  positionName.contains('nano-store-office-programmer-team-lead') ||
                                  positionName.contains('nano-vip-programmer-team-lead') ||
                                  positionName.contains('programmer team lead'));
    
    // Check if requester is Salesman
    final isSalesman = positionName.contains('salesman') || 
                       positionName.contains('sales person') ||
                       positionName.contains('sales');
    
    if (isNanoVip) {
      // NANO VIP → HR only
      allSteps = ['Employee', 'HR'];
    } else if (isHR) {
      // HR → Approver only
      allSteps = ['HR', 'Approver'];
    } else if (isProgrammerTeamLead) {
      // Programmer (Team Lead) → HR → Approver (skip Team Lead step)
      allSteps = ['Programmer', 'HR', 'Approver'];
    } else if (isProgrammer) {
      // Programmer → Team Lead → HR → Approver
      allSteps = ['Programmer', 'Team Lead', 'HR', 'Approver'];
    } else if (isSalesman) {
      // Salesman → Manager → HR → Approver
      allSteps = ['Employee', 'Manager', 'HR', 'Approver'];
    } else {
      // Other positions → HR → Approver
      allSteps = ['Employee', 'HR', 'Approver'];
    }
    
    // Filter out the requester step (first step) and only show approvers
    final steps = allSteps.length > 1 
        ? allSteps.sublist(1) // Skip first step (requester)
        : allSteps.where((step) {
            final stepLower = step.toLowerCase();
            return !stepLower.contains('employee') && 
                   !stepLower.contains('programmer') &&
                   !stepLower.contains('developer');
          }).toList();
    
    // If no approvers found, return empty container
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Determine which steps are completed based on status and approval history
    bool isRejected = statusLower == 'rejected';
    bool isApproved = statusLower == 'approved';
    bool isApprovedByManager = statusLower.contains('approved') && statusLower.contains('manager') && !statusLower.contains('warehouse');
    bool isApprovedByTeamLead = statusLower.contains('approved') && statusLower.contains('team_lead');
    bool isApprovedByWarehouseManager = statusLower.contains('approved') && statusLower.contains('warehouse_manager');
    bool isApprovedByHR = statusLower.contains('approved') && statusLower.contains('hr');
    
    // Helper function to check if a step is approved in approval history
    bool isStepApprovedInHistory(String stepName) {
      final stepNormalized = stepName.replaceAll('_', ' ').replaceAll('-', ' ').toLowerCase();
      
      for (final entry in approvalHistory) {
        if (entry is Map<String, dynamic>) {
          final entryLevel = (entry['level'] ?? '').toString().toLowerCase();
          final entryLevelNormalized = entryLevel.replaceAll('_', ' ').replaceAll('-', ' ');
          final entryAction = (entry['action'] ?? '').toString().toLowerCase();
          
          // Check if this entry matches the step
          bool isMatch = false;
          if (stepNormalized == entryLevelNormalized ||
              stepNormalized == entryLevel ||
              stepName.toLowerCase() == entryLevel) {
            isMatch = true;
          } else if ((stepNormalized.contains('team') && stepNormalized.contains('lead') && 
                     entryLevelNormalized.contains('team') && entryLevelNormalized.contains('lead')) ||
                    (stepNormalized.contains('hr') && entryLevelNormalized.contains('hr')) ||
                    (stepNormalized.contains('manager') && !stepNormalized.contains('warehouse') && 
                     entryLevelNormalized.contains('manager') && !entryLevelNormalized.contains('warehouse')) ||
                    (stepNormalized.contains('warehouse') && entryLevelNormalized.contains('warehouse')) ||
                    (stepNormalized.contains('approver') && entryLevelNormalized.contains('approver'))) {
            isMatch = true;
          }
          
          if (isMatch && entryAction == 'approve') {
            return true;
          }
        }
      }
      return false;
    }
    
    // Determine step statuses - check each step in order
    List<bool> stepApproved = List.generate(steps.length, (index) {
      final step = steps[index].toLowerCase();
      
      // If fully approved, all steps are approved
      if (isApproved) return true;
      
      // If rejected, no steps are approved
      if (isRejected) return false;
      
      // First, check approval history for this step
      final isApprovedInHistory = isStepApprovedInHistory(step);
      
      // Check each step type (handle different formats: "team_lead", "team lead", "Team Lead", etc.)
      final stepNormalized = step.replaceAll('_', ' ').replaceAll('-', ' ');
      
      bool isApprovedByStatus = false;
      if (stepNormalized.contains('manager') && !stepNormalized.contains('warehouse')) {
        isApprovedByStatus = isApprovedByManager;
      } else if (stepNormalized.contains('team') && stepNormalized.contains('lead')) {
        isApprovedByStatus = isApprovedByTeamLead;
      } else if (stepNormalized.contains('warehouse')) {
        isApprovedByStatus = isApprovedByWarehouseManager;
      } else if (stepNormalized.contains('hr') || stepNormalized.contains('human resource')) {
        isApprovedByStatus = isApprovedByHR;
      } else if (stepNormalized.contains('approver')) {
        // Approver step is approved only if HR is approved and request is fully approved
        isApprovedByStatus = isApprovedByHR && isApproved;
      }
      
      // Step is approved if found in history OR status indicates approval
      if (isApprovedInHistory || isApprovedByStatus) {
        return true;
      }
      
      // If a later step is approved, mark previous steps as approved too (sequential approval)
      // This handles cases where status shows "approved_hr" meaning Manager already approved
      for (int i = index + 1; i < steps.length; i++) {
        final laterStep = steps[i].toLowerCase();
        final laterStepNormalized = laterStep.replaceAll('_', ' ').replaceAll('-', ' ');
        
        // Check if later step is approved in history
        if (isStepApprovedInHistory(laterStep)) {
          return true;
        }
        
        // Check if later step is approved by status
        bool laterStepApproved = false;
        if (laterStepNormalized.contains('hr') && isApprovedByHR) {
          laterStepApproved = true;
        } else if (laterStepNormalized.contains('approver') && isApproved) {
          laterStepApproved = true;
        } else if (laterStepNormalized.contains('manager') && !laterStepNormalized.contains('warehouse') && isApprovedByManager) {
          laterStepApproved = true;
        }
        
        if (laterStepApproved) {
          return true;
        }
      }
      
      return false;
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LeaveTranslations.approveByStep(ref),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final stepIsApproved = stepApproved[index];
            final stepName = steps[index];
            final stepLower = stepName.toLowerCase();
            
            // Format step name for display (capitalize first letter of each word)
            String displayName = stepName
                .split(' ')
                .map((word) => word.isEmpty 
                    ? word 
                    : word[0].toUpperCase() + word.substring(1).toLowerCase())
                .join(' ');
            
            // Handle special cases - translate role names
            if (displayName.toLowerCase().contains('team') && displayName.toLowerCase().contains('lead')) {
              displayName = LeaveTranslations.teamLead(ref);
            } else if (displayName.toLowerCase().contains('hr') || displayName.toLowerCase().contains('human resource')) {
              displayName = LeaveTranslations.hr(ref);
            } else if (displayName.toLowerCase().contains('approver')) {
              displayName = LeaveTranslations.approver(ref);
            } else if (displayName.toLowerCase().contains('manager') && !displayName.toLowerCase().contains('warehouse')) {
              displayName = LeaveTranslations.manager(ref);
            } else if (displayName.toLowerCase().contains('warehouse')) {
              if (displayName.toLowerCase().contains('manager')) {
                displayName = LeaveTranslations.warehouseManager(ref);
              } else if (displayName.toLowerCase().contains('worker')) {
                displayName = LeaveTranslations.warehouseWorker(ref);
              } else if (displayName.toLowerCase().contains('administrator')) {
                displayName = LeaveTranslations.warehouseAdministrator(ref);
              }
            }
            
            // Find matching approval history entry to get userId and employee name
            String? approverName;
            String? approverUserId;
            // Use original step name (before translation) for matching
            final stepNormalized = stepLower.replaceAll('_', ' ').replaceAll('-', ' ');
            final approverNamesCache = (details['approverNames'] as Map<String, String>?) ?? {};
            
            
            // Try to match by level - find the approval entry that matches this step
            for (final entry in approvalHistory) {
              if (entry is Map<String, dynamic>) {
                final entryLevel = (entry['level'] ?? '').toString();
                final entryLevelLower = entryLevel.toLowerCase();
                final entryLevelNormalized = entryLevelLower.replaceAll('_', ' ').replaceAll('-', ' ');
                final entryAction = entry['action']?.toString().toLowerCase() ?? '';
                final entryUserId = entry['userId']?.toString();
                
                debugPrint('  Checking entry: level="$entryLevel" (normalized: "$entryLevelNormalized"), action="$entryAction", userId="$entryUserId"');
                
                // Match by level - check if this entry matches the current step
                // First try exact match (case-insensitive)
                bool isMatch = false;
                if (stepLower == entryLevelLower || 
                    stepNormalized == entryLevelNormalized ||
                    stepLower.replaceAll('_', '-') == entryLevelLower.replaceAll('_', '-') ||
                    stepLower.replaceAll('-', '_') == entryLevelLower.replaceAll('-', '_')) {
                  isMatch = true;
                  debugPrint('    → Exact match!');
                } else if ((stepNormalized.contains('team') && stepNormalized.contains('lead') && 
                           entryLevelNormalized.contains('team') && entryLevelNormalized.contains('lead')) ||
                          (stepNormalized.contains('hr') && entryLevelNormalized.contains('hr')) ||
                          (stepNormalized.contains('manager') && !stepNormalized.contains('warehouse') && 
                           entryLevelNormalized.contains('manager') && !entryLevelNormalized.contains('warehouse')) ||
                          (stepNormalized.contains('warehouse') && entryLevelNormalized.contains('warehouse')) ||
                          (stepNormalized.contains('approver') && entryLevelNormalized.contains('approver'))) {
                  isMatch = true;
                  debugPrint('    → Partial match!');
                }
                
                // If this step is approved, we should find an approval entry
                if (isMatch && entryAction == 'approve') {
                  approverUserId = entryUserId;
                  debugPrint('  ✓ Found matching approval entry! userId=$approverUserId');
                  
                  // Get employee name from cache (we fetched it earlier)
                  if (approverUserId != null && approverUserId.isNotEmpty) {
                    if (approverNamesCache.containsKey(approverUserId)) {
                      approverName = approverNamesCache[approverUserId];
                      debugPrint('  ✓ Found name in cache: "$approverName"');
                    } else {
                      debugPrint('  ⚠ Name not in cache for userId: $approverUserId');
                      debugPrint('  Cache contents: $approverNamesCache');
                      // Try to get from entry directly as fallback
                      approverName = entry['userName']?.toString() ?? 
                                    entry['approverName']?.toString() ??
                                    entry['name']?.toString();
                      debugPrint('  Name from entry (not in cache): $approverName');
                    }
                  } else {
                    debugPrint('  ⚠ approverUserId is null or empty');
                  }
                  break;
                } else if (isMatch && entryAction != 'approve') {
                  debugPrint('  → Match found but action is "$entryAction" (not "approve")');
                }
              }
            }
            
            if (approverUserId == null && stepIsApproved) {
              debugPrint('  ⚠ Warning: Step $displayName is approved but no userId found in approval history');
              debugPrint('  Approval history entries:');
              for (final entry in approvalHistory) {
                if (entry is Map<String, dynamic>) {
                  debugPrint('    - level: ${entry['level']}, action: ${entry['action']}, userId: ${entry['userId']}');
                }
              }
            }
            
            // Build display text
            String displayText;
            debugPrint('=== Approval Step Debug ===');
            debugPrint('Step: $displayName');
            debugPrint('Step Approved: $stepIsApproved');
            debugPrint('Approver UserId: $approverUserId');
            debugPrint('Approver Name: $approverName');
            debugPrint('Cache keys: ${approverNamesCache.keys}');
            debugPrint('Cache contains userId: ${approverNamesCache.containsKey(approverUserId)}');
            
            if (stepIsApproved) {
              if (approverName != null && approverName.isNotEmpty && approverName != approverUserId) {
                // Show role name and employee name
                displayText = '$displayName - $approverName';
              } else if (approverUserId != null && approverNamesCache.containsKey(approverUserId)) {
                // Try to get from cache one more time
                approverName = approverNamesCache[approverUserId];
                if (approverName != null && approverName.isNotEmpty) {
                  displayText = '$displayName - $approverName';
                } else {
                  displayText = '$displayName - ${LeaveTranslations.approvedStatus(ref)}';
                }
              } else {
                // Show approved even if name is not available
                displayText = '$displayName - ${LeaveTranslations.approvedStatus(ref)}';
              }
            } else {
              displayText = '$displayName - ${LeaveTranslations.pendingStatus(ref)}';
            }
            
            debugPrint('Final display text: $displayText');
            debugPrint('========================');
            
            return Column(
              children: [
                Row(
                  children: [
                    // Circular badge with checkmark
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: stepIsApproved ? Colors.teal : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: stepIsApproved
                          ? Icon(Icons.check, color: Colors.white, size: 20)
                          : Icon(Icons.person_outline, color: Colors.grey.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Person icon
                    Icon(Icons.person_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    // Step name with employee name text
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                // Vertical line connector (except for last item)
                if (index < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                    child: Container(
                      width: 2,
                      height: 24,
                      color: stepIsApproved ? Colors.teal.shade300 : Colors.grey.shade300,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
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
      List<String> managedBranches = [];
      try {
        leaveRequests = await leaveService.getAllLeaveRequestsForApproval(
          userLevel,
          currentEmployeeId,
        );
        // Get managedBranches from cache if available
        final cacheKey = '${userLevel}_$currentEmployeeId';
        final cachedData = LeaveService.getApprovalCache(cacheKey);
        if (cachedData != null && cachedData['managedBranches'] is List) {
          managedBranches = (cachedData['managedBranches'] as List)
              .map((e) => e.toString().toLowerCase())
              .toList();
        }
      } catch (e) {
        leaveRequests = [];
      }

      // Get current user's branch if user is a manager, team-lead, or warehouse-manager
      String? currentUserBranch;
      String? currentUserBranchCode;
      if (userLevel == 'manager' || userLevel == 'team-lead' || userLevel == 'warehouse-manager') {
        try {
          final apiService = ApiService();
          final profileResponse = await apiService.getEmployeeProfile(
            employeeId: currentEmployeeId,
          );
          if (profileResponse['success'] == true) {
            final employeeData = profileResponse['data'] ?? profileResponse['employee'];
            currentUserBranch = employeeData['branchName']?.toString() ?? 
                               employeeData['branch']?.toString();
            currentUserBranchCode = employeeData['branch']?.toString().toLowerCase() ?? 
                                   employeeData['branchCode']?.toString().toLowerCase();
          }
        } catch (e) {
          // If we can't get branch, continue without branch filtering
        }
      }

      final List<Map<String, dynamic>> teamRequests = [];
      for (final leaveRequest in leaveRequests) {
        // Skip own requests
        if (leaveRequest['employeeId'] == currentEmployeeId) {
          continue;
        }

        // Get employee's position, branch, and company from leave request
        final employeePosition = (leaveRequest['positionName']?.toString() ?? 
                                  leaveRequest['position']?.toString() ?? '').toLowerCase();
        final employeeBranchName = leaveRequest['branchName']?.toString() ?? '';
        final employeeBranchCode = (leaveRequest['branch']?.toString() ?? 
                                   leaveRequest['branchCode']?.toString() ?? '').toLowerCase();
        final employeeCompany = (leaveRequest['companyName']?.toString() ?? 
                                leaveRequest['company']?.toString() ?? '').toLowerCase();
        final isNanoVipEmployee = employeeCompany.contains('nano-vip') || employeeCompany.contains('nanovip');

        // For managers: filter out other managers and only show same branch salesmen
        if (userLevel == 'manager') {
          // Exclude other managers
          if (employeePosition.contains('manager') || 
              employeePosition.contains('supervisor')) {
            continue;
          }

          // Check if employee's branch is in manager's managed branches
          bool isInManagedBranch = false;
          if (managedBranches.isNotEmpty) {
            // Use managedBranches from API response (branch codes)
            isInManagedBranch = employeeBranchCode.isNotEmpty && 
                               managedBranches.contains(employeeBranchCode);
          } else if (currentUserBranchCode != null && currentUserBranchCode.isNotEmpty) {
            // Fallback: compare branch codes
            isInManagedBranch = employeeBranchCode == currentUserBranchCode;
          } else if (currentUserBranch != null && currentUserBranch.isNotEmpty) {
            // Fallback: compare branch names (case-insensitive)
            final employeeBranchNameLower = employeeBranchName.toLowerCase();
            final currentBranchLower = currentUserBranch.toLowerCase();
            isInManagedBranch = employeeBranchNameLower == currentBranchLower ||
                               employeeBranchNameLower.contains(currentBranchLower) ||
                               currentBranchLower.contains(employeeBranchNameLower);
          }

          // If branch doesn't match, skip this request
          if (!isInManagedBranch) {
            continue;
          }
        }

        // For team leads: show requests from all regular programmers (no branch restriction)
        // Also show nano-vip programmer requests (even though only HR can approve them)
        if (userLevel == 'team-lead') {
          // Exclude other team leads
          if (employeePosition.contains('programmer team lead') || 
              employeePosition.contains('programmer (team lead)') ||
              employeePosition.contains('nano-store-office-programmer-team-lead') ||
              employeePosition.contains('nano-vip-programmer-team-lead') ||
              employeePosition.contains('team lead') ||
              employeePosition.contains('team-lead')) {
            continue;
          }

          // Only show requests from programmers (but not team leads)
          // Check if employee is a programmer (but not a team lead)
          final isProgrammer = employeePosition.contains('programmer') || 
                              employeePosition.contains('developer') ||
                              employeePosition.contains('software engineer');
          
          // If not a programmer, skip (team leads only see programmers)
          // Exception: nano-vip programmers are shown even though workflow goes to HR
          if (!isProgrammer) {
            continue;
          }

          // No branch restriction - team lead can see all programmers (including nano-vip)
        }

        // For warehouse managers: filter out other warehouse managers and only show warehouse workers/administrators
        if (userLevel == 'warehouse-manager') {
          // Exclude other warehouse managers
          if (employeePosition.contains('warehouse manager')) {
            continue;
          }

          // Only show requests from warehouse workers and warehouse administrators
          if (!employeePosition.contains('warehouse worker') && 
              !employeePosition.contains('warehouse administrator')) {
            continue;
          }

          // Check if employee's branch is in warehouse manager's managed branches
          bool isInManagedBranch = false;
          if (managedBranches.isNotEmpty) {
            // Use managedBranches from API response (branch codes)
            isInManagedBranch = employeeBranchCode.isNotEmpty && 
                               managedBranches.contains(employeeBranchCode);
          } else if (currentUserBranchCode != null && currentUserBranchCode.isNotEmpty) {
            // Fallback: compare branch codes
            isInManagedBranch = employeeBranchCode == currentUserBranchCode;
          } else if (currentUserBranch != null && currentUserBranch.isNotEmpty) {
            // Fallback: compare branch names (case-insensitive)
            final employeeBranchNameLower = employeeBranchName.toLowerCase();
            final currentBranchLower = currentUserBranch.toLowerCase();
            isInManagedBranch = employeeBranchNameLower == currentBranchLower ||
                               employeeBranchNameLower.contains(currentBranchLower) ||
                               currentBranchLower.contains(employeeBranchNameLower);
          }

          // If branch doesn't match, skip this request
          if (!isInManagedBranch) {
            continue;
          }
        }

        // For HR: include warehouse worker/administrator requests that are approved by warehouse manager
        if (userLevel == 'hr') {
          final requestStatus = (leaveRequest['status']?.toString() ?? '').toLowerCase();
          final isApprovedByWarehouseManager =
              requestStatus == 'approved_warehouse_manager' ||
              requestStatus == 'approved_by_warehouse_manager' ||
              (requestStatus.contains('approved') && requestStatus.contains('warehouse_manager'));
          
          // If this is a warehouse worker/administrator request approved by warehouse manager, include it
          final isWarehouseEmployee = employeePosition.contains('warehouse worker') || 
                                     employeePosition.contains('warehouse administrator');
          
          if (isWarehouseEmployee && isApprovedByWarehouseManager) {
          teamRequests.add(leaveRequest);
            continue;
        }
        }

        teamRequests.add(leaveRequest);
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
    
    // Extract attachments from leave request data (as List<Map<String, dynamic>> like leave_list_screen)
    List<Map<String, dynamic>> attachments = [];
    
    // First, try from _leaveDetails (if already loaded)
    if (live != null && live['attachments'] != null && live['attachments'] is List) {
      final attList = live['attachments'] as List;
      // Convert to List<Map<String, dynamic>> if they're strings, otherwise use as-is
      attachments = attList.map((e) {
        if (e is String) {
          return {'publicUrl': e, 'url': e};
        } else if (e is Map<String, dynamic>) {
          return e;
        }
        return <String, dynamic>{};
      }).where((e) => e.isNotEmpty).toList();
      debugPrint('✓ Found ${attachments.length} attachments from _leaveDetails');
    } else {
      // Try to extract from notification data (the request object is stored here)
      try {
        // Check if attachments are already a list
        if (notification.data['attachments'] is List) {
          final attList = notification.data['attachments'] as List;
          attachments = attList.map((e) {
            if (e is String) {
              return {'publicUrl': e, 'url': e};
            } else if (e is Map<String, dynamic>) {
              return e;
            }
            return <String, dynamic>{};
          }).where((e) => e.isNotEmpty).toList();
          if (attachments.isNotEmpty) {
            debugPrint('✓ Found ${attachments.length} attachments from notification.data[attachments]');
          }
        }
        
        // If no attachments found, try to extract from attachment object
        // This matches the extraction logic in _showLeaveDetails
        if (attachments.isEmpty && notification.data['attachment'] != null) {
          final attachment = notification.data['attachment'];
          debugPrint('Checking attachment object: ${attachment.runtimeType}');
          
          if (attachment is Map<String, dynamic>) {
            // Check for files array (same as _showLeaveDetails)
            final files = attachment['files'];
            if (files is List) {
              attachments = files
                  .map((e) {
                    if (e is Map<String, dynamic>) {
                      return e;
                    } else if (e is String) {
                      return {'publicUrl': e, 'url': e};
                    }
                    return <String, dynamic>{};
                  })
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (attachments.isNotEmpty) {
                debugPrint('✓ Found ${attachments.length} attachments from attachment.files');
              }
            }
          }
        }
        
        if (attachments.isEmpty) {
          debugPrint('⚠ No attachments found. Notification data keys: ${notification.data.keys.toList()}');
        }
      } catch (e) {
        debugPrint('✗ Error extracting attachments: $e');
      }
    }
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

    final isApprovedByWarehouseManager =
        statusLower == 'approved_warehouse_manager' ||
        statusLower == 'approved_by_warehouse_manager' ||
        (statusLower.contains('approved') && statusLower.contains('warehouse_manager'));

    // Check if this is a nano-vip employee request
    final companyName = (notification.data['companyName'] ?? 
                        notification.data['company'] ?? '').toString().toLowerCase();
    final isNanoVipRequest = companyName.contains('nano-vip') || companyName.contains('nanovip');
    
    // For nano-vip requests, only HR can see approve/reject buttons
    final showActions = isNanoVipRequest
        ? (userLevel == 'hr' && (statusLower == 'pending' || statusLower == 'sent'))
        : userLevel == 'hr'
        ? (isPendingOrSent ||
              isApprovedByManager ||
              isApprovedByTeamLead ||
              isApprovedByWarehouseManager)
        : userLevel == 'approver'
        ? (isPendingOrSent ||
              isApprovedByHR) 
        : userLevel == 'team-lead'
        ? isPendingOrSent 
        : userLevel == 'warehouse-manager'
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
            // Top row: Person icon + Name + Status badge (top right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person icon on the left
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.kNanoGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // Name - aligned with other labels
                Expanded(
                  child: Text(
                        employeeName.isNotEmpty
                            ? employeeName
                            : 'Employee ${notification.senderId ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                ),
                // Status badge in top right
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
                                  statusLower.contains('manager') &&
                                  !statusLower.contains('warehouse'))
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
                        : statusLower == 'approved_warehouse_manager' ||
                              statusLower == 'approved_by_warehouse_manager' ||
                              (statusLower.contains('approved') &&
                                  statusLower.contains('warehouse_manager'))
                        ? Colors.indigo.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildStatusText(statusLower),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Employee ID - aligned with name (same left margin as name)
            Padding(
              padding: const EdgeInsets.only(left: 28), // Icon width (20) + spacing (8)
                  child: Text(
                employeeId.isNotEmpty ? employeeId : 'ID: Unknown',
                    style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            // Position - aligned with name
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                positionName.isNotEmpty
                    ? positionName
                    : 'Position: Unknown',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Display attachments if available - aligned with labels
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: _buildAttachmentsPreview(attachments),
              ),
            ],
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
                        onPressed: () => _showRejectReasonDialog(notification),
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

        

        // Extract approval history and fetch employee names
        final approvalHistoryList = (lr['approvalHistory'] ?? 
                                    lr['approval_history'] ?? 
                                    []) as List<dynamic>;
        
        // Fetch employee names for all userIds in approval history
        final Map<String, String> employeeNameCache = {};
        final apiService = ApiService();
        
        for (final entry in approvalHistoryList) {
          if (entry is Map<String, dynamic>) {
            final userId = entry['userId']?.toString();
            if (userId != null) {
              try {
                debugPrint('Fetching employee profile for userId: $userId');
                // Try the new endpoint first: /profile/:uid
                Map<String, dynamic> profileResponse;
                try {
                  profileResponse = await apiService.getEmployeeProfileByUid(userId);
                } catch (e) {
                  // Fallback to old endpoint
                  debugPrint('Failed with /profile/:uid, trying /employee/profile/:id: $e');
                  profileResponse = await apiService.getEmployeeProfile(employeeId: userId);
                }
                debugPrint('Profile response for $userId: ${profileResponse['success']}');
                
                if (profileResponse['success'] == true) {
                  final employeeData = profileResponse['data'] ?? profileResponse['employee'] ?? profileResponse;
                  debugPrint('Employee data for $userId: $employeeData');
                  debugPrint('Employee data keys: ${employeeData.keys}');
                  
                  // Try multiple possible field names
                  final nameStr = employeeData['name']?.toString() ?? '';
                  final firstName = employeeData['firstName'] ?? 
                                   employeeData['first_name'] ?? 
                                   (nameStr.isNotEmpty ? nameStr.split(' ').first : '') ?? '';
                  final lastName = employeeData['lastName'] ?? 
                                 employeeData['last_name'] ?? 
                                 (nameStr.isNotEmpty && nameStr.contains(' ') 
                                    ? nameStr.split(' ').skip(1).join(' ') 
                                    : '') ?? '';
                  
                  // If name field exists, use it directly
                  final nameField = employeeData['name']?.toString() ?? 
                                  employeeData['employeeName']?.toString() ??
                                  employeeData['fullName']?.toString();
                  
                  String fullName;
                  if (nameField != null && nameField.isNotEmpty) {
                    fullName = nameField.trim();
                  } else {
                    fullName = '${firstName} ${lastName}'.trim();
                  }
                  
                  debugPrint('Employee name for $userId: "$fullName" (firstName: "$firstName", lastName: "$lastName", nameField: $nameField)');
                  
                  if (fullName.isNotEmpty && fullName != userId) {
                    employeeNameCache[userId] = fullName;
                    debugPrint('✓ Stored name "$fullName" for userId $userId');
                  } else {
                    debugPrint('✗ Empty or invalid name for $userId');
                  }
                } else {
                  debugPrint('✗ Failed to fetch profile for $userId: ${profileResponse['message']}');
                }
              } catch (e) {
                // If fetching fails, continue without the name
                debugPrint('Exception fetching employee name for $userId: $e');
              }
            }
          }
        }
        
        debugPrint('=== Employee Name Cache Summary ===');
        debugPrint('Total entries in cache: ${employeeNameCache.length}');
        for (final entry in employeeNameCache.entries) {
          debugPrint('  $entry');
        }
        debugPrint('Approval history entries: ${approvalHistoryList.length}');
        for (final entry in approvalHistoryList) {
          if (entry is Map<String, dynamic>) {
            final userId = entry['userId']?.toString();
            final level = entry['level']?.toString();
            final action = entry['action']?.toString();
            debugPrint('  History entry: level=$level, action=$action, userId=$userId, hasName=${userId != null && employeeNameCache.containsKey(userId)}');
          }
        }
        debugPrint('===================================');

        details = {
          'leaveTypeName':
              lr['leaveTypeName'] ?? lr['leaveType'] ?? lr['requestType'],
          'fromDate': lr['fromDate'],
          'toDate': lr['toDate'],
          'totalDays': lr['totalDays'],
          'requestType': lr['requestType'],
          'reason': lr['reason'],
          'status': lr['status'] ?? lr['statusName'],
          'rejectReason': lr['rejectReason'] ?? 
                         lr['rejectionReason'] ?? 
                         lr['rejectedReason'] ?? 
                         lr['rejection_reason'] ?? 
                         lr['reject_reason'],
          'approvedByName': lr['approvedByName'],
          'approvalWorkflow': lr['approvalWorkflow'] ?? 
                             lr['approval_workflow'] ??
                             notification.data['approvalWorkflow'] ??
                             notification.data['approval_workflow'],
          'approvalHistory': approvalHistoryList,
          'approverNames': employeeNameCache, // Cache of userId -> employee name
          'companyName': lr['companyName'] ?? 
                       notification.data['companyName'] ?? 
                       lr['company'] ?? 
                       notification.data['company'],
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
        final Color statusColor = _getStatusColor(statusLower);
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
                      child: _buildStatusTextForDetail(statusLower, statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Approval Steps Section
                _buildApprovalSteps(d, statusLower),
                const SizedBox(height: 16),
                
                _detailRow(LeaveTranslations.fromDate(ref).replaceAll(':', ''), d['fromDate']),
                _detailRow(LeaveTranslations.toDate(ref).replaceAll(':', ''), d['toDate']),
                _detailRow(LeaveTranslations.totalDaysLabel(ref).replaceAll(':', ''), d['totalDays']?.toString()),
                _detailRow(LeaveTranslations.requestType(ref), d['requestType']),
                _detailRow(LeaveTranslations.reason(ref), d['reason']),
                if (statusLower == 'rejected' && d['rejectReason'] != null && d['rejectReason'].toString().isNotEmpty)
                  _detailRow(LeaveTranslations.rejectionReason(ref), d['rejectReason']),
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

  Future<void> _showRejectReasonDialog(NotificationModel notification) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LeaveTranslations.rejectLeaveRequest(ref)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LeaveTranslations.pleaseProvideRejectionReason(ref),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: '${LeaveTranslations.rejectionReason(ref)} *',
                  hintText: LeaveTranslations.enterRejectionReason(ref),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LeaveTranslations.rejectionReasonRequired(ref);
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LeaveTranslations.cancel(ref)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _decide(notification, false, reasonController.text.trim(), rejectReason: reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(LeaveTranslations.rejectLeaveRequest(ref)),
          ),
        ],
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
    String note, {
    String? rejectReason,
  }) async {
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
        final leaveRequestData = details['leaveRequest'] ?? details['data'] ?? {};
        final currentStatus =
            leaveRequestData['status'] ??
            details['status'];

        // Check if this is a nano-vip employee request
        final companyName = (leaveRequestData['companyName'] ?? 
                            leaveRequestData['company'] ?? 
                            notification.data['companyName'] ?? 
                            notification.data['company'] ?? '').toString().toLowerCase();
        final isNanoVipRequest = companyName.contains('nano-vip') || companyName.contains('nanovip');

        final userLevel = _getUserLevel(auth);
        final statusLower = currentStatus?.toString().toLowerCase() ?? '';

        // For nano-vip requests, only HR can approve/reject
        if (isNanoVipRequest && userLevel != 'hr') {
          if (mounted) Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only HR can approve/reject leave requests from NANO-VIP employees.',
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

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

        final isApprovedByWarehouseManager =
            statusLower == 'approved_warehouse_manager' ||
            statusLower == 'approved_by_warehouse_manager' ||
            (statusLower.contains('approved') && statusLower.contains('warehouse_manager'));

        // For nano-vip requests, only HR can act (already checked above, but ensure canAct reflects this)
        final canAct = isNanoVipRequest
            ? (userLevel == 'hr' && isPendingOrSent)
            : userLevel == 'hr'
            ? (isPendingOrSent ||
                  isApprovedByManager ||
                  isApprovedByTeamLead ||
                  isApprovedByWarehouseManager) 
            : userLevel == 'approver'
            ? (isPendingOrSent ||
                  isApprovedByHR) 
            : userLevel == 'warehouse-manager'
            ? isPendingOrSent
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
        rejectReason: !approve ? (rejectReason ?? note) : null,
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
          rejectReason: !approve ? (rejectReason ?? note) : null,
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

  String _getStatusText(String statusLower) {
    if (statusLower == 'approved') {
      return 'Approved';
    } else if (statusLower == 'rejected') {
      return 'Rejected';
    } else if (statusLower == 'approved_manager' ||
               statusLower == 'approved_by_manager' ||
               (statusLower.contains('approved') &&
                statusLower.contains('manager') &&
                !statusLower.contains('warehouse'))) {
      return 'Approved Manager';
    } else if (statusLower == 'approved_hr' ||
               statusLower == 'approved_by_hr' ||
               (statusLower.contains('approved') && statusLower.contains('hr'))) {
      return 'Approved HR';
    } else if (statusLower == 'approved_team_lead' ||
               statusLower == 'approved_by_team_lead' ||
               (statusLower.contains('approved') && statusLower.contains('team_lead'))) {
      return 'Approved Team Lead';
    } else if (statusLower == 'approved_warehouse_manager' ||
               statusLower == 'approved_by_warehouse_manager' ||
               (statusLower.contains('approved') && statusLower.contains('warehouse_manager'))) {
      return 'Approved WH Mgr';
    } else if (statusLower == 'pending' || statusLower == 'sent') {
      return 'Pending';
    } else {
      // Fallback: format the status nicely
      return statusLower
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isEmpty 
              ? word 
              : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }

  Color _getStatusColor(String statusLower) {
    if (statusLower == 'approved') {
      return Colors.green[700]!;
    } else if (statusLower == 'rejected') {
      return Colors.red[700]!;
    } else if (statusLower == 'approved_manager' ||
               statusLower == 'approved_by_manager' ||
               (statusLower.contains('approved') &&
                statusLower.contains('manager') &&
                !statusLower.contains('warehouse'))) {
      return Colors.blue[700]!;
    } else if (statusLower == 'approved_hr' ||
               statusLower == 'approved_by_hr' ||
               (statusLower.contains('approved') && statusLower.contains('hr'))) {
      return Colors.purple[700]!;
    } else if (statusLower == 'approved_team_lead' ||
               statusLower == 'approved_by_team_lead' ||
               (statusLower.contains('approved') && statusLower.contains('team_lead'))) {
      return Colors.teal[700]!;
    } else if (statusLower == 'approved_warehouse_manager' ||
               statusLower == 'approved_by_warehouse_manager' ||
               (statusLower.contains('approved') && statusLower.contains('warehouse_manager'))) {
      return Colors.indigo[700]!;
    } else {
      return Colors.orange[700]!;
    }
  }

  Widget _buildStatusText(String statusLower) {
    return Text(
      _getStatusText(statusLower),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _getStatusColor(statusLower),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusTextForDetail(String statusLower, Color statusColor) {
    return Text(
      _getStatusText(statusLower),
      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAttachmentsPreview(List<Map<String, dynamic>> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppTheme.kNanoGold),
            const SizedBox(width: 8),
            Text(
              '${LeaveTranslations.attachmentsLabel(ref)} (${attachments.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.kNanoGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            final url = attachment['publicUrl'] ?? attachment['url'] ?? attachment['firebaseUrl'] ?? '';
            final fileName =
                attachment['originalName'] ??
                attachment['fileName'] ??
                attachment['name'] ??
                url.split('/').last;
            final fileType = attachment['fileType'] ?? attachment['type'] ?? '';
            final contentType = attachment['contentType'] ?? attachment['mimeType'] ?? '';

            // Check if it's an image by multiple methods
            final isImage = _isImageFile(fileName, url) || 
                           (fileType.toString().toLowerCase().contains('image')) ||
                           (contentType.toString().toLowerCase().startsWith('image/'));

            return GestureDetector(
              onTap: () => _openAttachment(url, allAttachments: attachments, initialIndex: index),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isImage && url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFD4A574).withOpacity(0.3),
                              child: Icon(
                                Icons.image,
                                color: AppTheme.kNanoGold,
                                size: 32,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFD4A574).withOpacity(0.3),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.kNanoGold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: const Color(0xFFD4A574).withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            _getFileIcon(fileName),
                            color: AppTheme.kNanoGold,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isImageFile(String fileName, [String? url]) {
    // Check filename extension
    if (fileName.contains('.')) {
      final extension = fileName.toLowerCase().split('.').last;
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'].contains(extension)) {
        return true;
      }
    }
    
    // Check URL if provided
    if (url != null && url.isNotEmpty) {
      final urlLower = url.toLowerCase();
      // Check if URL contains image extensions
      if (urlLower.contains('.jpg') || 
          urlLower.contains('.jpeg') || 
          urlLower.contains('.png') || 
          urlLower.contains('.gif') || 
          urlLower.contains('.bmp') || 
          urlLower.contains('.webp') ||
          urlLower.contains('.heic') ||
          urlLower.contains('.heif')) {
        return true;
      }
      // Check if it's a Firebase Storage URL with image content type
      if (urlLower.contains('firebasestorage') || urlLower.contains('storage.googleapis.com')) {
        // Assume it's an image if we can't determine otherwise (common for Firebase URLs)
        // But also check for common non-image patterns
        if (!urlLower.contains('.pdf') && 
            !urlLower.contains('.doc') && 
            !urlLower.contains('.xls') &&
            !urlLower.contains('.zip')) {
          return true;
        }
      }
    }
    
    return false;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _openAttachment(String url, {List<Map<String, dynamic>>? allAttachments, int? initialIndex}) async {
    if (allAttachments != null && allAttachments.isNotEmpty) {
      // Extract URLs from attachment objects for full-screen viewer
      final List<String> imageUrls = allAttachments
          .map((att) => att['publicUrl']?.toString() ?? att['url']?.toString() ?? att['firebaseUrl']?.toString() ?? '')
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList();
      
      if (imageUrls.isNotEmpty) {
        final index = initialIndex != null && initialIndex < imageUrls.length 
            ? initialIndex 
            : imageUrls.indexOf(url);
        if (index >= 0) {
          _showFullScreenImage(context, imageUrls, index);
        } else {
          _showFullScreenImage(context, imageUrls, 0);
        }
      }
    } else {
      // Fallback: show single image
      _showFullScreenImage(context, [url], 0);
    }
  }

  void _showFullScreenImage(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality can be added here if needed
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
