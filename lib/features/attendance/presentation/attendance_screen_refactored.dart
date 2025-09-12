import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_hr_mobile/features/attendance/data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../../app/theme.dart';
import 'widgets/attendance_header.dart';
import 'widgets/attendance_button.dart';
import 'widgets/attendance_history_modal.dart';

/// Refactored attendance screen with improved structure and separation of concerns
class AttendanceScreenRefactored extends ConsumerStatefulWidget {
  const AttendanceScreenRefactored({super.key});

  @override
  ConsumerState<AttendanceScreenRefactored> createState() =>
      _AttendanceScreenRefactoredState();
}

class _AttendanceScreenRefactoredState
    extends ConsumerState<AttendanceScreenRefactored> {
  Map<String, dynamic>? _employeeProfile;
  Map<String, dynamic>? _attendanceStatus;
  bool _isLoadingStatus = false;
  bool _isLoadingProfile = false;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeProfile();
  }

  /// Load employee profile and attendance status
  Future<void> _loadEmployeeProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.getEmployeeProfile();

      if (response['success'] == true) {
        setState(() {
          _employeeProfile = response['employee'];
        });
        await _loadAttendanceStatus();
      } else {
        _showErrorSnackBar('Failed to load profile: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar(ErrorHandler.handleException(e));
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  /// Load current attendance status
  Future<void> _loadAttendanceStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        _showErrorSnackBar('No employee ID found');
        return;
      }

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        setState(() {
          _attendanceStatus = response;
        });
      } else {
        _showErrorSnackBar('Failed to load status: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar(ErrorHandler.handleException(e));
    } finally {
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  /// Handle check-in/out action
  Future<void> _handleAttendanceAction() async {
    if (_isProcessingAction) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        _showErrorSnackBar('No employee ID found');
        return;
      }

      final attendanceController = ref.read(
        attendanceControllerProvider.notifier,
      );
      await attendanceController.toggleCheck();

      // Refresh status after action
      await _loadAttendanceStatus();

      _showSuccessSnackBar('Attendance updated successfully');
    } catch (e) {
      _showErrorSnackBar(ErrorHandler.handleException(e));
    } finally {
      setState(() {
        _isProcessingAction = false;
      });
    }
  }

  /// Show attendance history modal
  void _showAttendanceHistory() {
    final authService = ref.read(authServiceProvider);
    final employeeId = authService.currentEmployeeId;

    if (employeeId == null) {
      _showErrorSnackBar('No employee ID found');
      return;
    }

    final apiService = ref.read(apiServiceProvider);
    final historyFuture = _loadAttendanceHistory(employeeId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AttendanceHistoryModal(historyFuture: historyFuture),
    );
  }

  /// Load attendance history
  Future<List<Attendance>> _loadAttendanceHistory(String employeeId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getAttendanceList(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        final outerData = response['data'] as Map<String, dynamic>;
        if (outerData['success'] == true) {
          final data = outerData['data'] as List<dynamic>;
          final records = data.cast<Map<String, dynamic>>();

          return records.map((json) => Attendance.fromJson(json)).toList();
        }
      }

      throw Exception('Failed to load attendance history');
    } catch (e) {
      throw Exception(ErrorHandler.handleException(e));
    }
  }

  /// Get button configuration based on current status
  Map<String, dynamic> _getButtonConfig() {
    final status = _attendanceStatus?['status'] ?? 'not_checked_in';
    final canCheckIn = _attendanceStatus?['canCheckIn'] ?? false;
    final canCheckOut = _attendanceStatus?['canCheckOut'] ?? false;
    final buttonText =
        _attendanceStatus?['buttonText'] ?? AppConstants.checkInButton;

    String displayText;
    bool isEnabled;
    Color? backgroundColor;

    if (status == 'checked_out') {
      displayText = AppConstants.alreadyCheckedOutButton;
      isEnabled = false;
      backgroundColor = Colors.grey;
    } else if (canCheckIn) {
      displayText = AppConstants.checkInButton;
      isEnabled = true;
      backgroundColor = AppTheme.kNanoGold;
    } else if (canCheckOut) {
      displayText = AppConstants.checkOutButton;
      isEnabled = true;
      backgroundColor = Colors.green;
    } else {
      displayText = buttonText;
      isEnabled = false;
      backgroundColor = Colors.grey;
    }

    return {
      'text': displayText,
      'enabled': isEnabled,
      'backgroundColor': backgroundColor,
    };
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            AttendanceHeader(
              employeeProfile: _employeeProfile,
              attendanceStatus: _attendanceStatus,
              isLoading: _isLoadingProfile || _isLoadingStatus,
            ),

            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  children: [
                    // Check-in/out Button
                    _buildActionButton(),

                    const SizedBox(height: AppConstants.largePadding),

                    // Status Cards
                    _buildStatusCards(),

                    const Spacer(),

                    // History Button
                    _buildHistoryButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final buttonConfig = _getButtonConfig();

    return AttendanceButton(
      buttonText: buttonConfig['text'],
      onPressed: buttonConfig['enabled'] ? _handleAttendanceAction : null,
      isLoading: _isProcessingAction,
      isEnabled: buttonConfig['enabled'],
      backgroundColor: buttonConfig['backgroundColor'],
    );
  }

  Widget _buildStatusCards() {
    return Column(
      children: [
        StatusCard(
          title: 'Today\'s Date',
          value: AppDateUtils.formatDateOnly(AppDateUtils.getToday()),
          icon: Icons.calendar_today,
          onTap: _showAttendanceHistory,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        StatusCard(
          title: 'Current Time',
          value: AppDateUtils.formatTimeOnly(AppDateUtils.getThailandTime()),
          icon: Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAttendanceHistory,
        icon: const Icon(Icons.history),
        label: const Text('View Attendance History'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.kNanoGold,
          side: BorderSide(color: AppTheme.kNanoGold),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    );
  }
}
