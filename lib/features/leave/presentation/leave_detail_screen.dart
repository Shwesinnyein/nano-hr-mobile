import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/leave_service.dart';
import '../utils/leave_translations.dart';

class LeaveDetailScreen extends ConsumerStatefulWidget {
  final String leaveId;
  final NotificationModel? notification;
  final bool showActions;

  const LeaveDetailScreen({
    super.key,
    required this.leaveId,
    this.notification,
    this.showActions = true,
  });

  @override
  ConsumerState<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends ConsumerState<LeaveDetailScreen> {
  Map<String, dynamic>? _details;
  bool _loading = true;
  String? _error;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadLeaveDetails();
  }

  Future<void> _loadLeaveDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = LeaveService();
      final res = await service.getLeaveDetails(widget.leaveId);

      if (res['success'] == true) {
        final lr = res['leaveRequest'] ?? res['data'] ?? {};
        final notification = widget.notification;

        // Extract approval history and fetch employee names
        final approvalHistoryList = (lr['approvalHistory'] ?? 
                                    lr['approval_history'] ?? 
                                    []) as List<dynamic>;
        
        // Debug: Print approval history to see what we're getting
        print('=== LEAVE DETAILS API RESPONSE ===');
        print('Leave ID: ${widget.leaveId}');
        print('Status: ${lr['status'] ?? lr['statusName']}');
        print('Approval History Count: ${approvalHistoryList.length}');
        print('Approval History: $approvalHistoryList');
        print('Full Leave Request Data Keys: ${lr.keys.toList()}');
        if (lr.containsKey('rejectedBy')) print('rejectedBy: ${lr['rejectedBy']}');
        if (lr.containsKey('rejected_by')) print('rejected_by: ${lr['rejected_by']}');
        if (lr.containsKey('rejectedByRole')) print('rejectedByRole: ${lr['rejectedByRole']}');
        if (lr.containsKey('rejected_by_role')) print('rejected_by_role: ${lr['rejected_by_role']}');
        print('===================================');
        
        // Fetch employee names for all userIds in approval history
        final Map<String, String> employeeNameCache = {};
        final apiService = ApiService();
        
        // Also fetch position for the leave requester if not available
        String? employeePosition;
        final employeeId = notification?.data['employeeId'] ?? 
                          lr['employeeId'] ?? 
                          lr['employee_id'];
        
        // Check if position is already available
        final existingPosition = notification?.data['positionName'] ??
                                 lr['positionName'] ??
                                 lr['position'] ??
                                 lr['position_name'] ??
                                 lr['employeePosition'] ??
                                 lr['employee_position'];
        
        // If position is not available and we have employeeId, fetch it
        if (existingPosition == null && employeeId != null && employeeId.toString().isNotEmpty) {
          try {
            Map<String, dynamic> profileResponse;
            try {
              profileResponse = await apiService.getEmployeeProfileByUid(employeeId.toString());
            } catch (e) {
              profileResponse = await apiService.getEmployeeProfile(employeeId: employeeId.toString());
            }
            
            if (profileResponse['success'] == true) {
              final employeeData = profileResponse['data'] ?? profileResponse['employee'] ?? profileResponse;
              employeePosition = employeeData['positionName']?.toString() ??
                                employeeData['position']?.toString() ??
                                employeeData['position_name']?.toString() ??
                                employeeData['employeePosition']?.toString() ??
                                employeeData['employee_position']?.toString();
            }
          } catch (e) {
            // Continue without position
          }
        }
        
        for (final entry in approvalHistoryList) {
          if (entry is Map<String, dynamic>) {
            final userId = entry['userId']?.toString();
            if (userId != null) {
              try {
                Map<String, dynamic> profileResponse;
                try {
                  profileResponse = await apiService.getEmployeeProfileByUid(userId);
                } catch (e) {
                  profileResponse = await apiService.getEmployeeProfile(employeeId: userId);
                }
                
                if (profileResponse['success'] == true) {
                  final employeeData = profileResponse['data'] ?? profileResponse['employee'] ?? profileResponse;
                  
                  final nameStr = employeeData['name']?.toString() ?? '';
                  final firstName = employeeData['firstName'] ?? 
                                   employeeData['first_name'] ?? 
                                   (nameStr.isNotEmpty ? nameStr.split(' ').first : '') ?? '';
                  final lastName = employeeData['lastName'] ?? 
                                 employeeData['last_name'] ?? 
                                 (nameStr.isNotEmpty && nameStr.contains(' ') 
                                    ? nameStr.split(' ').skip(1).join(' ') 
                                    : '') ?? '';
                  
                  final nameField = employeeData['name']?.toString() ?? 
                                  employeeData['employeeName']?.toString() ??
                                  employeeData['fullName']?.toString();
                  
                  String fullName;
                  if (nameField != null && nameField.isNotEmpty) {
                    fullName = nameField.trim();
                  } else {
                    fullName = '${firstName} ${lastName}'.trim();
                  }
                  
                  if (fullName.isNotEmpty && fullName != userId) {
                    employeeNameCache[userId] = fullName;
                  }
                }
              } catch (e) {
                // Continue without the name
              }
            }
          }
        }

        _details = {
          'leaveTypeName':
              lr['leaveTypeName'] ?? lr['leaveType'] ?? lr['requestType'],
          'fromDate': lr['fromDate'],
          'toDate': lr['toDate'],
          'totalDays': lr['totalDays'],
          'totalHours': lr['totalHours'],
          'date': lr['date'],
          'startTime': lr['startTime'],
          'endTime': lr['endTime'],
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
                             notification?.data['approvalWorkflow'] ??
                             notification?.data['approval_workflow'],
          'approvalHistory': approvalHistoryList,
          'approverNames': employeeNameCache,
          'companyName': lr['companyName'] ?? 
                       notification?.data['companyName'] ?? 
                       lr['company'] ?? 
                       notification?.data['company'],
          'employeeName':
              notification?.data['employeeName'] ??
              lr['employeeName'] ??
              (lr['firstName'] != null && lr['lastName'] != null
                  ? '${lr['firstName']} ${lr['lastName']}'
                  : lr['firstName'] ?? lr['lastName'] ?? 'Unknown Employee'),
          'firstName': notification?.data['firstName'] ?? lr['firstName'],
          'lastName': notification?.data['lastName'] ?? lr['lastName'],
          'positionName':
              notification?.data['positionName'] ??
              lr['positionName'] ??
              lr['position'] ??
              lr['position_name'] ??
              lr['employeePosition'] ??
              lr['employee_position'] ??
              employeePosition ??
              'Unknown Position',
          'employeeId':
              notification?.data['employeeId'] ??
              lr['employeeId'] ??
              lr['employee_id'] ??
              'Unknown ID',
          'attachments': (() {
            try {
              final attachment = lr['attachment'];
              if (attachment is Map<String, dynamic>) {
                final files = attachment['files'];
                if (files is List) {
                  // Return full attachment objects, not just URLs
                  return files
                      .map((e) {
                        if (e is Map<String, dynamic>) {
                          return e;
                        } else if (e is String) {
                          // If it's just a URL string, convert to object
                          return {'publicUrl': e, 'url': e, 'firebaseUrl': e};
                        }
                        return null;
                      })
                      .whereType<Map<String, dynamic>>()
                      .toList();
                }
              }
              return <Map<String, dynamic>>[];
            } catch (e) {
              return <Map<String, dynamic>>[];
            }
          })(),
        };
      } else {
        _error = res['message']?.toString() ?? 'Failed to load leave details';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase().trim();
    
    // Fully approved
    if (statusLower == 'approved' || statusLower == 'approved_by_approver') {
      return AppTheme.successColor;
    }
    
    // Rejected
    if (statusLower == 'rejected' || statusLower.contains('rejected')) {
      return AppTheme.errorColor;
    }
    
    // Partially approved - different colors for different approvers
    if (statusLower == 'approved_manager' ||
        statusLower == 'approved_by_manager' ||
        (statusLower.contains('approved') &&
         statusLower.contains('manager') &&
         !statusLower.contains('warehouse'))) {
      return Colors.blue[700]!;
    }
    
    if (statusLower == 'approved_hr' ||
        statusLower == 'approved_by_hr' ||
        (statusLower.contains('approved') && statusLower.contains('hr'))) {
      return Colors.purple[700]!;
    }
    
    if (statusLower == 'approved_team_lead' ||
        statusLower == 'approved_by_team_lead' ||
        (statusLower.contains('approved') && statusLower.contains('team_lead'))) {
      return Colors.teal[700]!;
    }
    
    if (statusLower == 'approved_warehouse_manager' ||
        statusLower == 'approved_by_warehouse_manager' ||
        (statusLower.contains('approved') && statusLower.contains('warehouse_manager'))) {
      return Colors.indigo[700]!;
    }
    
    // Pending
    return AppTheme.warningColor;
  }

  String _getStatusText(String status) {
    final statusLower = status.toLowerCase().trim();
    
    // Fully approved
    if (statusLower == 'approved' || statusLower == 'approved_by_approver') {
      return 'Approved';
    }
    
    // Rejected
    if (statusLower == 'rejected' || statusLower.contains('rejected')) {
      return 'Rejected';
    }
    
    // Partially approved - show which level approved
    if (statusLower == 'approved_manager' ||
        statusLower == 'approved_by_manager' ||
        (statusLower.contains('approved') &&
         statusLower.contains('manager') &&
         !statusLower.contains('warehouse'))) {
      return 'Approved by Manager';
    }
    
    if (statusLower == 'approved_hr' ||
        statusLower == 'approved_by_hr' ||
        (statusLower.contains('approved') && statusLower.contains('hr'))) {
      return 'Approved by HR';
    }
    
    if (statusLower == 'approved_team_lead' ||
        statusLower == 'approved_by_team_lead' ||
        (statusLower.contains('approved') && statusLower.contains('team_lead'))) {
      return 'Approved by Team Lead';
    }
    
    if (statusLower == 'approved_warehouse_manager' ||
        statusLower == 'approved_by_warehouse_manager' ||
        (statusLower.contains('approved') && statusLower.contains('warehouse_manager'))) {
      return 'Approved by WH Mgr';
    }
    
    // Pending or sent
    if (statusLower == 'pending' || statusLower == 'sent' || statusLower.isEmpty) {
      return 'Pending';
    }
    
    // Fallback: format the status nicely
    return statusLower
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty 
            ? word 
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildStatusText(String status, Color color) {
    final statusText = _getStatusText(status);
    return Text(
      statusText,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSteps(Map<String, dynamic> details, String statusLower) {
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
    
    // Check if requester is Warehouse Worker
    final isWarehouseWorker = positionName.contains('warehouse worker') || 
                              positionName.contains('warehouse-worker') ||
                              positionName.contains('warehouse_worker');
    
    // Check if requester is Warehouse Administrator
    final isWarehouseAdministrator = positionName.contains('warehouse administrator') || 
                                     positionName.contains('warehouse-administrator') ||
                                     positionName.contains('warehouse_administrator') ||
                                     positionName.contains('warehouse administrator');
    
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
    } else if (isWarehouseWorker || isWarehouseAdministrator) {
      // Warehouse Worker or Warehouse Administrator → Warehouse Manager → HR → Approver
      allSteps = ['Employee', 'Warehouse Manager', 'HR', 'Approver'];
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
                   !stepLower.contains('developer') &&
                   !stepLower.contains('warehouse worker') &&
                   !stepLower.contains('warehouse administrator');
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
    
    // Helper function to check if a step matches an entry level
    bool _stepMatchesLevel(String stepName, String entryLevel) {
      final stepNormalized = stepName.replaceAll('_', ' ').replaceAll('-', ' ').toLowerCase();
      final entryLevelLower = entryLevel.toLowerCase();
      final entryLevelNormalized = entryLevelLower.replaceAll('_', ' ').replaceAll('-', ' ');
      
      // Exact match
      if (stepNormalized == entryLevelNormalized ||
          stepNormalized == entryLevelLower ||
          stepName.toLowerCase() == entryLevelLower) {
        return true;
      }
      
      // Fuzzy match for variations
      if ((stepNormalized.contains('team') && stepNormalized.contains('lead') && 
           entryLevelNormalized.contains('team') && entryLevelNormalized.contains('lead')) ||
          (stepNormalized.contains('hr') && entryLevelNormalized.contains('hr')) ||
          (stepNormalized.contains('manager') && !stepNormalized.contains('warehouse') && 
           entryLevelNormalized.contains('manager') && !entryLevelNormalized.contains('warehouse')) ||
          (stepNormalized.contains('warehouse') && entryLevelNormalized.contains('warehouse')) ||
          (stepNormalized.contains('approver') && entryLevelNormalized.contains('approver'))) {
        return true;
      }
      
      return false;
    }
    
    // Helper function to check if a step is approved in approval history
    bool isStepApprovedInHistory(String stepName) {
      for (final entry in approvalHistory) {
        if (entry is Map<String, dynamic>) {
          final entryLevel = (entry['level'] ?? '').toString();
          final entryAction = (entry['action'] ?? '').toString().toLowerCase();
          
          if (_stepMatchesLevel(stepName, entryLevel) && entryAction == 'approve') {
            return true;
          }
        }
      }
      return false;
    }
    
    // Helper function to check if a step is rejected in approval history
    bool isStepRejectedInHistory(String stepName) {
      for (final entry in approvalHistory) {
        if (entry is Map<String, dynamic>) {
          final entryLevel = (entry['level'] ?? '').toString();
          final entryAction = (entry['action'] ?? '').toString().toLowerCase();
          
          if (_stepMatchesLevel(stepName, entryLevel) && entryAction == 'reject') {
            return true;
          }
        }
      }
      return false;
    }
    
    // Helper function to find rejection entry for a step
    Map<String, dynamic>? findRejectionEntry(String stepName) {
      for (final entry in approvalHistory) {
        if (entry is Map<String, dynamic>) {
          final entryLevel = (entry['level'] ?? '').toString();
          final entryAction = (entry['action'] ?? '').toString().toLowerCase();
          
          if (_stepMatchesLevel(stepName, entryLevel) && entryAction == 'reject') {
            return entry;
          }
        }
      }
      return null;
    }
    
    // Debug: Print approval history for step matching
    print('=== BUILDING APPROVAL STEPS ===');
    print('Steps: $steps');
    print('Approval History: $approvalHistory');
    print('Status: $statusLower');
    
    // Find the first rejected step index
    int? firstRejectedStepIndex;
    for (int i = 0; i < steps.length; i++) {
      final stepLower = steps[i].toLowerCase();
      final isRejected = isStepRejectedInHistory(stepLower);
      print('Step $i ($stepLower): isRejected = $isRejected');
      if (isRejected) {
        firstRejectedStepIndex = i;
        print('Found rejected step at index $i');
        break;
      }
    }
    print('First rejected step index: $firstRejectedStepIndex');
    print('================================');
    
    // Determine step statuses - check each step in order
    List<bool> stepApproved = List.generate(steps.length, (index) {
      final step = steps[index].toLowerCase();
      
      // If fully approved, all steps are approved
      if (isApproved) return true;
      
      // If there's a rejection, check each step individually
      if (firstRejectedStepIndex != null) {
        // Steps before rejection: check if they were approved in history
        if (index < firstRejectedStepIndex!) {
          return isStepApprovedInHistory(step);
        }
        // The rejected step itself: not approved
        if (index == firstRejectedStepIndex!) {
          return false;
        }
        // Steps after rejection: pending (not approved)
        return false;
      }
      
      // No rejection - check normally
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
    
    // Also track which steps are rejected
    List<bool> stepRejected = List.generate(steps.length, (index) {
      return isStepRejectedInHistory(steps[index].toLowerCase());
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
            final stepIsRejected = stepRejected[index];
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
            
            // Build display text - simplified: just show step name and status
            String displayText;
            if (stepIsRejected) {
              // Show rejected status
              displayText = '$displayName - ${LeaveTranslations.rejectedStatus(ref)}';
            } else if (stepIsApproved) {
              // Show approved status
              displayText = '$displayName - ${LeaveTranslations.approvedStatus(ref)}';
            } else {
              // Pending status
              displayText = '$displayName - ${LeaveTranslations.pendingStatus(ref)}';
            }
            
            // Determine colors and icons
            final stepColor = stepIsRejected 
                ? Colors.red 
                : (stepIsApproved ? Colors.teal : Colors.grey.shade300);
            final stepIcon = stepIsRejected 
                ? Icons.close 
                : (stepIsApproved ? Icons.check : Icons.person_outline);
            final textColor = stepIsRejected 
                ? Colors.red 
                : Colors.grey.shade900;
            
            return Column(
              children: [
                Row(
                  children: [
                    // Circular badge with icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: stepColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(stepIcon, color: Colors.white, size: 20),
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
                          color: textColor,
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
                      color: stepIsRejected 
                          ? Colors.red.shade300 
                          : (stepIsApproved ? Colors.teal.shade300 : Colors.grey.shade300),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview(List attachments) {
    // Convert to List<Map<String, dynamic>> if needed
    List<Map<String, dynamic>> attachmentList = [];
    for (var att in attachments) {
      if (att is Map<String, dynamic>) {
        attachmentList.add(att);
      } else if (att is String) {
        attachmentList.add({'publicUrl': att, 'url': att, 'firebaseUrl': att});
      }
    }

    if (attachmentList.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppTheme.kNanoGold),
            const SizedBox(width: 8),
            Text(
              'Attachments (${attachmentList.length})',
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
          children: attachmentList.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            final url = attachment['publicUrl']?.toString() ?? 
                       attachment['url']?.toString() ?? 
                       attachment['firebaseUrl']?.toString() ?? '';
            final fileName =
                attachment['originalName']?.toString() ??
                attachment['fileName']?.toString() ??
                attachment['name']?.toString() ??
                url.split('/').last;
            final fileType = attachment['fileType']?.toString() ?? attachment['type']?.toString() ?? '';
            final contentType = attachment['contentType']?.toString() ?? attachment['mimeType']?.toString() ?? '';

            // Check if it's an image
            final isImage = _isImageFile(fileName, url) || 
                           (fileType.toLowerCase().contains('image')) ||
                           (contentType.toLowerCase().startsWith('image/'));

            return GestureDetector(
              onTap: () => _openAttachment(url, allAttachments: attachmentList, initialIndex: index),
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
      if (urlLower.contains('firebasestorage') || urlLower.contains('storage.googleapis.com')) {
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

  bool _canApproveOrReject() {
    // CRITICAL: Don't show actions if explicitly disabled (e.g., from leave history)
    // This is the primary gate - if false, never show buttons regardless of status
    if (!widget.showActions) {
      return false;
    }
    
    if (_details == null) return false;
    
    // Don't show Approve/Reject to the requester (employee who submitted the leave).
    // Only approvers (HR, Manager, Team Lead, Approver, etc.) should see these buttons.
    final requesterId = (_details!['employeeId'] ?? _details!['employee_id'] ?? '').toString().trim();
    final currentUserId = ref.read(authServiceProvider).currentEmployeeId?.trim() ?? '';
    if (requesterId.isNotEmpty && currentUserId.isNotEmpty && requesterId == currentUserId) {
      return false; // Current user is the requester — view only
    }
    
    final status = (_details!['status'] ?? 'Pending').toString().trim();
    final statusLower = status.toLowerCase();
    
    // Check if already fully approved - be very explicit about this
    // "approved" (exact match, case-insensitive) means fully approved
    if (statusLower == 'approved') {
      return false; // Fully approved - no actions needed
    }
    
    // Also check for "approved_by_approver" which is the final approval
    if (statusLower == 'approved_by_approver' || 
        statusLower == 'approved by approver') {
      return false; // Fully approved - no actions needed
    }
    
    // Check if status contains "approved" but is NOT an intermediate status
    // Intermediate statuses: approved_hr, approved_manager, approved_team_lead, approved_warehouse_manager
    // If it contains "approved" but none of the intermediate qualifiers, it's fully approved
    if (statusLower.contains('approved')) {
      final hasIntermediateQualifier = statusLower.contains('_hr') ||
                                      statusLower.contains('_manager') ||
                                      statusLower.contains('_team_lead') ||
                                      statusLower.contains('_warehouse_manager') ||
                                      statusLower.contains('by_hr') ||
                                      statusLower.contains('by_manager') ||
                                      statusLower.contains('by_team_lead') ||
                                      statusLower.contains('by_warehouse_manager') ||
                                      statusLower.contains('by hr') ||
                                      statusLower.contains('by manager') ||
                                      statusLower.contains('by team lead') ||
                                      statusLower.contains('by warehouse manager');
      
      // If it contains "approved" but no intermediate qualifier, it's fully approved
      if (!hasIntermediateQualifier) {
        return false; // Fully approved - no actions needed
      }
    }
    
    // Check if already rejected
    if (statusLower == 'rejected' || 
        statusLower.contains('rejected')) {
      return false; // Already rejected - no actions needed
    }
    
    // For intermediate approval statuses (approved_hr, approved_manager, etc.)
    // or pending statuses, check if user can still act
    // But we need notification to determine user role and permissions
    if (widget.notification == null) {
      // If no notification, assume read-only (from leave history)
      return false;
    }
    
    // Check if status is pending or in intermediate approval state
    final isPending = statusLower == 'pending' || 
                     statusLower == 'sent' ||
                     statusLower.isEmpty;
    
    // Intermediate approval statuses that might still need action
    final isIntermediateApproval = statusLower.contains('approved_hr') ||
                                   statusLower.contains('approved_manager') ||
                                   statusLower.contains('approved_team_lead') ||
                                   statusLower.contains('approved_warehouse_manager') ||
                                   statusLower.contains('approved_by_hr') ||
                                   statusLower.contains('approved_by_manager') ||
                                   statusLower.contains('approved_by_team_lead') ||
                                   statusLower.contains('approved_by_warehouse_manager');
    
    // Only allow actions if pending or in intermediate approval state
    return isPending || isIntermediateApproval;
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

  Future<void> _handleApprove() async {
    if (widget.notification == null) return;
    await _decide(widget.notification!, true, '');
  }

  Future<void> _handleReject() async {
    if (widget.notification == null) return;
    _showRejectReasonDialog(widget.notification!);
  }

  void _showRejectReasonDialog(NotificationModel notification) {
    final rejectReasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LeaveTranslations.rejectLeaveRequest(ref)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LeaveTranslations.pleaseProvideRejectionReason(ref)),
            const SizedBox(height: 12),
            TextField(
              controller: rejectReasonController,
              decoration: InputDecoration(
                labelText: '${LeaveTranslations.rejectionReason(ref)} *',
                hintText: LeaveTranslations.enterRejectionReason(ref),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LeaveTranslations.cancel(ref)),
          ),
          ElevatedButton(
            onPressed: () {
              if (rejectReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LeaveTranslations.rejectionReasonRequired(ref))),
                );
                return;
              }
              Navigator.pop(context);
              _decide(notification, false, '', rejectReason: rejectReasonController.text.trim());
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
        widget.leaveId;
    if (leaveId == null || leaveId.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing leave ID')),
        );
      }
      return;
    }

    if (!mounted) return;
    String loadingText = 'Saving...';
    StateSetter? setDialogState;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
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
      final service = LeaveService();
      final leaveIdStr = leaveId.toString();

      updateLoadingText('Checking leave details...');
      final details = await service.getLeaveDetails(leaveIdStr);

      if (details['success'] == true) {
        final leaveRequestData = details['leaveRequest'] ?? details['data'] ?? {};
        final currentStatus =
            leaveRequestData['status'] ??
            details['status'];

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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Only HR can approve/reject leave requests from NANO-VIP employees.',
                ),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
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
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'This request is already $currentStatus. Refreshing...',
                ),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
          await _loadLeaveDetails();
          return;
        }
      }

      updateLoadingText('Processing...');
      final status = approve ? 'approved' : 'rejected';
      final userRole = _getUserLevel(auth);
      final res = await service.updateLeaveStatus(
        leaveId: leaveIdStr,
        status: status,
        approverId: approverId,
        userRole: userRole,
        note: note,
        rejectReason: !approve ? (rejectReason ?? note) : null,
      );

      if (res['success'] == true) {
        if (mounted) Navigator.of(context).pop(); // Close loading dialog

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
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
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                    if (mounted) {
                      context.pop(true); // Go back to approval screen with refresh flag
                    }
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppTheme.kNanoGold),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        // Try alternative endpoint
        final alt = await service.approveOrRejectLeave(
          leaveId: leaveIdStr,
          action: approve ? 'approve' : 'reject',
          approverId: approverId,
          userRole: userRole,
          note: note,
          rejectReason: !approve ? (rejectReason ?? note) : null,
        );
        
        if (mounted) Navigator.of(context).pop();

        if (alt['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
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
                    onPressed: () {
                      Navigator.of(context).pop(); // Close success dialog
                      if (mounted) {
                        context.pop(true); // Go back to approval screen with refresh flag
                      }
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(color: AppTheme.kNanoGold),
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  alt['message']?.toString() ?? 
                  res['message']?.toString() ?? 
                  'Failed to ${approve ? 'approve' : 'reject'} leave request',
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LeaveTranslations.leaveDetails(ref)),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LeaveTranslations.leaveDetails(ref)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_details == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LeaveTranslations.leaveDetails(ref)),
        ),
        body: const Center(
          child: Text('No details available'),
        ),
      );
    }

    final d = _details!;
    final status = (d['status'] ?? 'Pending').toString();
    final statusLower = status.toLowerCase();
    final statusColor = _getStatusColor(statusLower);
    
    // CRITICAL: If showActions is false (from leave list/history), NEVER show buttons
    // This ensures complete separation between approval screen and history view
    final canApproveReject = widget.showActions && _canApproveOrReject() && !_processing;

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          LeaveTranslations.leaveDetails(ref),
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
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.kOnBackground),
            onPressed: () => _loadLeaveDetails(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  child: _buildStatusText(statusLower, statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Approval Steps Section
            _buildApprovalSteps(d, statusLower),
            const SizedBox(height: 16),
            
            // Show different fields based on request type
            if (d['requestType']?.toString().toLowerCase() == 'hourly') ...[
              _detailRow('Date', d['date']),
              _detailRow('Start Time', d['startTime']),
              _detailRow('End Time', d['endTime']),
              _detailRow('Total Hours', d['totalHours']?.toString()),
            ] else ...[
              _detailRow(LeaveTranslations.fromDate(ref).replaceAll(':', ''), d['fromDate']),
              _detailRow(LeaveTranslations.toDate(ref).replaceAll(':', ''), d['toDate']),
              _detailRow(LeaveTranslations.totalDaysLabel(ref).replaceAll(':', ''), d['totalDays']?.toString()),
            ],
            _detailRow(
              LeaveTranslations.requestType(ref), 
              (d['requestType']?.toString().toLowerCase() == 'hourly')
                  ? LeaveTranslations.hourly(ref)
                  : LeaveTranslations.daily(ref),
            ),
            _detailRow(LeaveTranslations.reason(ref), d['reason']),
            if (statusLower == 'rejected' && d['rejectReason'] != null && d['rejectReason'].toString().isNotEmpty)
              _detailRow(LeaveTranslations.rejectionReason(ref), d['rejectReason']),
            if (d['employeeName'] != null)
              _detailRow(LeaveTranslations.employeeName(ref), d['employeeName']),
            if (d['positionName'] != null)
              _detailRow(LeaveTranslations.position(ref), d['positionName']),
            if (d['employeeId'] != null)
              _detailRow(LeaveTranslations.employeeId(ref), d['employeeId']),
            if (d['approvedByName'] != null)
              _detailRow('Approved By', d['approvedByName']),
            const SizedBox(height: 8),
            if (d['attachments'] != null &&
                (d['attachments'] as List).isNotEmpty) ...[
              _buildAttachmentsPreview(d['attachments'] as List),
              const SizedBox(height: 16),
            ],
            
            // Approve/Reject Buttons
            // CRITICAL: Only show buttons if showActions is true AND canApproveOrReject returns true
            // This ensures complete separation - when viewing from leave list (showActions=false), buttons NEVER show
            if (widget.showActions && canApproveReject) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _handleReject,
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
                        onPressed: _handleApprove,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
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
