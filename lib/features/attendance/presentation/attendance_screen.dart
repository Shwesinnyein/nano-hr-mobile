import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_hr_mobile/features/attendance/data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../app/theme.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showDetails = false;
  Map<String, dynamic>? _employeeProfile;
  Map<String, dynamic>? _attendanceStatus;
  bool _isLoadingStatus = false;

  String fmt(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
  String fmtDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy').format(dt.toLocal());
  String fmtFull(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());

  // Helper method to get button text and state based on attendance status
  // Helper method to get button text and state based on attendance status
  Map<String, dynamic> _getButtonState(List<Attendance> entries) {
    final todayEntries = entries.where((entry) {
      final entryDate = DateTime(
        entry.checkInAt.year,
        entry.checkInAt.month,
        entry.checkInAt.day,
      );
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      return entryDate.isAtSameMomentAs(today);
    }).toList();

    // Determine status from attendance data
    final hasCheckedIn = todayEntries.isNotEmpty;
    final hasCheckedOut =
        todayEntries.isNotEmpty && todayEntries.last.checkOutAt != null;

    // Use API status data if available, otherwise fall back to attendance data
    String? apiStatus = _attendanceStatus?['status'];
    bool isCheckedInFromAPI = apiStatus == 'checked_in';
    bool isCheckedOutFromAPI = apiStatus == 'checked_out';

    final finalHasCheckedIn = _attendanceStatus != null
        ? isCheckedInFromAPI
        : hasCheckedIn;
    final finalHasCheckedOut = _attendanceStatus != null
        ? isCheckedOutFromAPI
        : hasCheckedOut;

    final bool canCheckIn = !finalHasCheckedIn;
    final bool canCheckOut = finalHasCheckedIn && !finalHasCheckedOut;

    String buttonText;
    IconData buttonIcon;
    List<Color> buttonColors;
    bool isEnabled;

    if (canCheckIn) {
      buttonText = 'Check In';
      buttonIcon = Icons.login;
      buttonColors = [AppTheme.kNanoGold, AppTheme.kNanoGoldDark];
      isEnabled = true;
    } else if (canCheckOut) {
      buttonText = 'Check Out';
      buttonIcon = Icons.logout;
      buttonColors = [AppTheme.kNanoGoldDark, AppTheme.kNanoGold];
      isEnabled = true;
    } else {
      // Already checked out for today
      buttonText = 'Already Checked Out';
      buttonIcon = Icons.check_circle;
      buttonColors = [Colors.grey, Colors.grey.shade600];
      isEnabled = false;
    }

    return {
      'text': buttonText,
      'icon': buttonIcon,
      'colors': buttonColors,
      'enabled': isEnabled,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeProfile();
  }

  Future<void> _loadEmployeeProfile() async {
    try {
      final authService = ref.read(authServiceProvider);

      final response = await authService.getEmployeeProfile();

      if (response['success'] == true) {
        setState(() {
          _employeeProfile = response['employee'];
        });

        await _loadAttendanceStatus();
      } else {
        await _loadAttendanceStatusWithEmployeeId(
          authService.currentEmployeeId,
        );
      }
    } catch (e) {
      final authService = ref.read(authServiceProvider);
      await _loadAttendanceStatusWithEmployeeId(authService.currentEmployeeId);
    }
  }

  Future<void> _loadAttendanceStatus() async {
    try {
      if (_employeeProfile == null) return;

      setState(() {
        _isLoadingStatus = true;
      });

      final apiService = ref.read(apiServiceProvider);
      final employeeId = _employeeProfile!['uid'];

      final response = await apiService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        setState(() {
          _attendanceStatus = response;
          _isLoadingStatus = false;
        });

        final record = response['record'];
        if (record != null) {}
      } else {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _loadAttendanceStatusWithEmployeeId(String? employeeId) async {
    if (employeeId == null) {
      return;
    }

    try {
      setState(() {
        _isLoadingStatus = true;
      });

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        setState(() {
          _attendanceStatus = response;
          _isLoadingStatus = false;
        });

        final record = response['record'];
        if (record != null) {}
      } else {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  // Method to refresh attendance status after check-in/out
  Future<void> _refreshAttendanceStatus() async {
    if (_employeeProfile != null) {
      await _loadAttendanceStatus();
    } else {
      final authService = ref.read(authServiceProvider);
      await _loadAttendanceStatusWithEmployeeId(authService.currentEmployeeId);
    }
  }

  // Load attendance history directly from API
  Future<List<Attendance>> _loadAttendanceHistory(WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        print('❌ No employee ID for history');
        return [];
      }

      print('🔍 Loading attendance history for: $employeeId');
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getAttendanceList(
        employeeId: employeeId,
      );

      print('🔍 History API response: $response');

      if (response['success'] == true) {
        // Handle nested data structure
        final outerData = response['data'] as Map<String, dynamic>;
        if (outerData['success'] == true) {
          final data = outerData['data'] as List<dynamic>;
          final records = data.cast<Map<String, dynamic>>();

          print('🔍 Parsed ${records.length} records from API');

          // Convert to Attendance objects
          final attendanceList = records.map((json) {
            return Attendance.fromJson(json);
          }).toList();

          print('🔍 Created ${attendanceList.length} Attendance objects');
          return attendanceList;
        }
      }

      print('❌ Failed to load history: ${response['message']}');
      return [];
    } catch (e) {
      print('❌ Error loading attendance history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);

    if (!authService.isAuthenticated) {
      return Container(
        color: AppTheme.kBackground,
        child: const Center(child: Text('Please login first')),
      );
    }

    if (_employeeProfile == null || _isLoadingStatus) {
      return Container(
        color: AppTheme.kBackground,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
          ),
        ),
      );
    }

    // Use employee ID from profile
    final employeeId = _employeeProfile!['id'] ?? _employeeProfile!['uid'];

    final controller = ref.read(attendanceControllerProvider.notifier);
    final state = ref.watch(attendanceControllerProvider);

    if (state.hasError) {
      print('❌ AttendanceScreen: Error detected: ${state.error}');
    }

    return Container(
      color: AppTheme.kBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header with today's date and status
            _buildHeader(context, ref, state),
            const SizedBox(height: 20),
            // Check In/Out Button
            _buildCheckInOutButton(context, ref, controller, state),
            const SizedBox(height: 20),
            // View Details Button
            _buildViewDetailsButton(context, ref, state),
            // Recent Attendance List (only show if details are visible)
            if (_showDetails) ...[
              const SizedBox(height: 20),
              _buildAttendanceList(ref, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Attendance>> state,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Top row with profile photo and name
          Row(
            children: [
              // Profile Photo - Left corner
              GestureDetector(
                onTap: () {
                  context.go('/profile');
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _employeeProfile?['profileImage'] != null
                        ? Image.network(
                            _employeeProfile!['profileImage'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            'assets/icon/nano-store-dark.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _employeeProfile?['firstName'] +
                              ' ' +
                              _employeeProfile?['lastName'] ??
                          'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Today's date
          Text(
            'Today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmtDate(DateTime.now()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Working Hours
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Working Hours: 9:00 AM - 7:00 PM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Location
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_employeeProfile?['companyName'] ?? 'NANO-STORES'} - ${_employeeProfile?['locationName'] ?? 'Office'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Check in/out status card
          _buildStatusCard(state),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AsyncValue<List<Attendance>> state) {
    if (state is AsyncLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (state is AsyncError) {
      return Center(
        child: Text(
          'Error loading attendance data',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: state.when(
        data: (entries) {
          final todayEntries = entries.where((entry) {
            final entryDate = DateTime(
              entry.checkInAt.year,
              entry.checkInAt.month,
              entry.checkInAt.day,
            );
            final today = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            return entryDate.isAtSameMomentAs(today);
          }).toList();

          String? apiStatus = _attendanceStatus?['status'];
          bool isCheckedInFromAPI = apiStatus == 'checked_in';
          bool isCheckedOutFromAPI = apiStatus == 'checked_out';

          bool hasApiRecord =
              _attendanceStatus != null && _attendanceStatus!['record'] != null;

          final finalHasCheckedIn = hasApiRecord
              ? isCheckedInFromAPI
              : todayEntries.isNotEmpty;
          final finalHasCheckedOut = hasApiRecord
              ? isCheckedOutFromAPI
              : (todayEntries.isNotEmpty &&
                    todayEntries.last.checkOutAt != null);

          String? checkInTime;
          String? checkOutTime;

          if (_attendanceStatus != null &&
              _attendanceStatus!['record'] != null) {
            final record = _attendanceStatus!['record'];
            checkInTime = record['checkInAt']?.toString();
            checkOutTime = record['checkOutAt']?.toString();
          }

          // Fallback to attendance data times if API times not available
          if (checkInTime == null && todayEntries.isNotEmpty) {
            checkInTime = fmt(todayEntries.last.checkInAt);
          }
          if (checkOutTime == null &&
              todayEntries.isNotEmpty &&
              todayEntries.last.checkOutAt != null) {
            checkOutTime = fmt(todayEntries.last.checkOutAt!);
          }

          return Column(
            children: [
              // Status icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  finalHasCheckedIn && !finalHasCheckedOut
                      ? Icons.login
                      : finalHasCheckedIn && finalHasCheckedOut
                      ? Icons.logout
                      : Icons.access_time,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              // Status text
              Text(
                checkInTime != null && checkOutTime != null
                    ? 'Checked Out'
                    : checkInTime != null
                    ? 'Checked In'
                    : 'Not Checked In',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Time display from API response
              if (checkInTime != null) ...[
                Text(
                  'Check In: $checkInTime',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (checkOutTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Check Out: $checkOutTime',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading attendance...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Column(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 40),
            const SizedBox(height: 16),
            Text(
              'Error loading status',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInOutButton(
    BuildContext context,
    WidgetRef ref,
    dynamic controller,
    AsyncValue<List<Attendance>> state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: state.when(
        data: (entries) {
          // Get button state from helper method
          final buttonState = _getButtonState(entries);

          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: buttonState['colors']),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kNanoGold.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: buttonState['enabled']
                  ? () => _handleCheckInOut(context, ref, controller)
                  : null, // Disable button if already checked out
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonState['icon'], color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    buttonState['text'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCheckInOut(
    BuildContext context,
    WidgetRef ref,
    dynamic controller,
  ) async {
    try {
      await controller.toggleCheck();

      // Refresh attendance status after successful action
      await _refreshAttendanceStatus();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleCheckInOut(context, ref, controller),
            ),
          ),
        );
      }
    }
  }

  void _refreshAttendance(WidgetRef ref) {
    ref.invalidate(attendanceControllerProvider);
  }

  Widget _buildViewDetailsButton(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Attendance>> state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            _showAttendanceDetails(context, state);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                color: AppTheme.kNanoGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'View Details',
                style: TextStyle(
                  color: AppTheme.kNanoGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList(
    WidgetRef ref,
    AsyncValue<List<Attendance>> state,
  ) {
    return Container(
      height: 300, // Fixed height to prevent overflow
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: state.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No attendance records',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final a = entries[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.kBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.kNanoGold.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Status icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: a.checkOutAt == null
                                  ? AppTheme.kNanoGold.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              a.checkOutAt == null ? Icons.login : Icons.logout,
                              color: a.checkOutAt == null
                                  ? AppTheme.kNanoGold
                                  : Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fmtDate(a.checkInAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'In: ${fmt(a.checkInAt)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                if (a.checkOutAt != null) ...[
                                  Text(
                                    'Out: ${fmt(a.checkOutAt!)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Location
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppTheme.kNanoGold,
                                size: 16,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.location,
                                style: TextStyle(
                                  color: AppTheme.kNanoGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading attendance',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        return ElevatedButton.icon(
                          onPressed: () => _refreshAttendance(ref),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kNanoGold,
                            foregroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(
    BuildContext context,
    AsyncValue<List<Attendance>> state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<List<Attendance>>(
        future: _loadAttendanceHistory(ref),
        builder: (context, snapshot) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppTheme.kNanoGold,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Attendance Details',
                        style: TextStyle(
                          color: AppTheme.kNanoGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: _buildHistoryContent(snapshot)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryContent(AsyncSnapshot<List<Attendance>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
            ),
            SizedBox(height: 16),
            Text(
              'Loading attendance history...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading attendance',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final entries = snapshot.data ?? [];
    print('🔍 Attendance History: Total entries: ${entries.length}');

    for (int i = 0; i < entries.length; i++) {
      print('🔍 Entry $i: ${entries[i].toJson()}');
    }

    if (entries.isEmpty) {
      return const Center(child: Text('No attendance records'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.kNanoGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${_formatDateHeader(entry.date)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Check In time
                if (entry.checkInAt != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.login,
                        color: AppTheme.kNanoGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Check In: ${_formatTimeOnly(entry.checkInAt)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Check Out time
                if (entry.checkOutAt != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Check Out: ${_formatTimeOnly(entry.checkOutAt)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Location: ${entry.location}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Date formatting helper functions
String fmtDate(DateTime? date) {
  if (date == null) return 'N/A';
  return DateFormat('MMM dd, yyyy').format(date);
}

String fmt(DateTime? date) {
  if (date == null) return 'N/A';
  return DateFormat('HH:mm').format(date);
}

String fmtFull(DateTime? date) {
  if (date == null) return 'N/A';
  return DateFormat('MMM dd, yyyy HH:mm').format(date);
}

String _formatDateHeader(String dateString) {
  try {
    // Parse the date string (assuming format YYYY-MM-DD)
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    // If parsing fails, return the original string
    return dateString;
  }
}

String _formatTimeOnly(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';
  return DateFormat('HH:mm:ss').format(dateTime);
}
