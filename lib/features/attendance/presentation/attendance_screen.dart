import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nano_hr_mobile/features/attendance/data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/animated_fade_in.dart';
import 'package:intl/intl.dart';
import 'check_in_confirmation_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/branch_location_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showDetails = false;
  Map<String, dynamic>? _employeeProfile;
  Map<String, dynamic>? _attendanceStatus;
  Map<String, dynamic>? _shiftData;
  bool _isLoadingStatus = false;

  // Location tracking
  final LocationService _locationService = LocationService();
  Map<String, dynamic>? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  String fmt(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
  String fmtDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy').format(dt.toLocal());
  String fmtFull(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());

  // Helper method to get button text and state based on attendance status
  // Helper method to get button text and state based on attendance status
  Map<String, dynamic> _getButtonState(List<Attendance> entries) {
    // Use API attendance data directly instead of filtering local entries
    final attendanceData = _shiftData?['attendanceData'] as List?;
    final latestRecord = attendanceData?.isNotEmpty == true
        ? attendanceData!.first
        : null;
    final hasCheckedIn = latestRecord?['checkInAt'] != null;
    final hasCheckedOut = latestRecord?['checkOutAt'] != null;

    print('🔍 Button State Debug:');
    print('  - latestRecord: $latestRecord');
    print('  - checkInAt: ${latestRecord?['checkInAt']}');
    print('  - checkOutAt: ${latestRecord?['checkOutAt']}');
    print('  - hasCheckedIn: $hasCheckedIn');
    print('  - hasCheckedOut: $hasCheckedOut');

    // Use actual check-in/check-out times to determine button state
    final finalHasCheckedIn = hasCheckedIn;
    final finalHasCheckedOut = hasCheckedOut;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _loadCurrentLocation();
    });
  }

  Future<void> _loadInitialData() async {
    print('🚀 _loadInitialData started');

    if (_employeeProfile != null &&
        _attendanceStatus != null &&
        _shiftData != null) {
      print('✅ Data already loaded, returning early');
      return;
    }

    try {
      print('📱 Setting loading state to true');
      setState(() {
        _isLoadingStatus = true;
      });

      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      print('🔍 Auth check:');
      print('  - employeeId: $employeeId');
      print('  - isAuthenticated: ${authService.isAuthenticated}');

      if (employeeId == null) {
        print('❌ No employee ID found');
        setState(() {
          _isLoadingStatus = false;
        });
        return;
      }

      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('📅 Calling API with:');
      print('  - employeeId: $employeeId');
      print('  - date: $dateString');

      // Only call getShiftDataWithFilter - it provides all needed data
      final shiftDataResponse = await apiService.getShiftDataWithFilter(
        employeeId: employeeId,
        date: dateString,
      );

      print('📡 API Response received:');
      print('  - success: ${shiftDataResponse['success']}');
      print('  - message: ${shiftDataResponse['message']}');
      print('  - response keys: ${shiftDataResponse.keys}');

      if (mounted) {
        setState(() {
          if (shiftDataResponse['success'] == true) {
            // The API response structure is direct, not wrapped in 'data'
            _shiftData = shiftDataResponse;

            // Extract employee profile from shift data
            if (_shiftData?['employee'] != null) {
              _employeeProfile = _shiftData!['employee'];
              print('👤 Extracted Employee Profile: $_employeeProfile');
            } else {
              print('❌ No employee data in shift response');
            }

            // Extract attendance status from shift data
            if (_shiftData?['attendanceData'] != null) {
              _attendanceStatus = {
                'success': true,
                'data': _shiftData!['attendanceData'],
                'record': _shiftData!['attendanceData'].isNotEmpty
                    ? _shiftData!['attendanceData'][0]
                    : null,
              };
            }

            print('🔍 RAW API Response: $shiftDataResponse');
            print('📊 Shift Data: $_shiftData');
            print('📊 Employee from Shift: ${_getEmployeeFromShiftData()}');
            print('📊 Working Hours: ${_getWorkingHoursDisplay()}');
            print('📊 Today Attendance: ${_getTodayAttendanceFromShiftData()}');
            print('📊 Employee Profile: $_employeeProfile');
            print('📊 Attendance Status: $_attendanceStatus');
            print('📊 Employee Name: ${_getEmployeeName()}');
          } else {
            print('❌ Shift Data Error: ${shiftDataResponse['message']}');
          }
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      print('❌ Error loading initial data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load attendance data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final locationData = await _locationService
          .getCurrentLocationWithAddress();

      if (mounted) {
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Method to refresh attendance status after check-in/out
  Future<void> _refreshAttendanceStatus() async {
    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) return;

      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await apiService.getShiftDataWithFilter(
        employeeId: employeeId,
        date: dateString,
      );

      if (response['success'] == true) {
        setState(() {
          // The API response structure is direct, not wrapped in 'data'
          _shiftData = response;

          // Update employee profile from shift data
          if (_shiftData?['employee'] != null) {
            _employeeProfile = _shiftData!['employee'];
          }

          // Update attendance status from shift data
          if (_shiftData?['attendanceData'] != null) {
            final attendanceData = _shiftData!['attendanceData'];
            final hasAttendanceData = attendanceData.isNotEmpty;
            final latestRecord = hasAttendanceData ? attendanceData[0] : null;

            // Determine status based on attendance data
            String status = 'not_checked_in';
            if (hasAttendanceData && latestRecord != null) {
              if (latestRecord['checkInAt'] != null &&
                  latestRecord['checkOutAt'] == null) {
                status = 'checked_in';
              } else if (latestRecord['checkInAt'] != null &&
                  latestRecord['checkOutAt'] != null) {
                status = 'checked_out';
              }
            }

            _attendanceStatus = {
              'success': true,
              'status': status,
              'data': attendanceData,
              'record': latestRecord,
            };

            print('🔄 Refreshed attendance status: $status');
            print('🔄 Attendance record: $latestRecord');
          }
        });
      }
    } catch (e) {
      // Handle error silently for refresh
    }
  }

  Future<List<Attendance>> _loadAttendanceHistory(WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) return [];

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getAttendanceList(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        final outerData = response['data'] as Map<String, dynamic>;
        if (outerData['success'] == true) {
          final data = outerData['data'] as List<dynamic>;
          return data
              .take(50)
              .map((json) => Attendance.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    super.dispose();
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

    if (_isLoadingStatus) {
      return Container(
        color: AppTheme.kBackground,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
              SizedBox(height: 16),
              Text(
                'Loading attendance data...',
                style: TextStyle(
                  color: AppTheme.kNanoGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = ref.read(attendanceControllerProvider.notifier);
    final state = ref.watch(attendanceControllerProvider);

    if (state.hasError) {}

    return Container(
      color: AppTheme.kBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header with today's date and status
            AnimatedFadeIn(
              delay: const Duration(milliseconds: 100),
              child: _buildHeader(context, ref, state),
            ),
            const SizedBox(height: 20),
            AnimatedFadeIn(
              delay: const Duration(milliseconds: 200),
              child: _buildCheckInOutButton(context, ref, controller, state),
            ),
            const SizedBox(height: 20),
            AnimatedFadeIn(
              delay: const Duration(milliseconds: 300),
              child: _buildViewDetailsButton(context, ref, state),
            ),
            if (_showDetails) ...[
              const SizedBox(height: 20),
              AnimatedSlideIn(
                delay: const Duration(milliseconds: 400),
                child: _buildAttendanceList(ref, state),
              ),
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
                  child: ClipOval(child: _buildProfileImage()),
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
                      _getEmployeeName() ?? 'Loading...',
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
                  _getWorkingHoursDisplay(),
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
          // Office Location
          Container(
            width: double.infinity,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getLocationDisplayText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

          // Get attendance status from multiple sources
          String? apiStatus = _attendanceStatus?['status'];
          bool isCheckedInFromAPI = apiStatus == 'checked_in';
          bool isCheckedOutFromAPI = apiStatus == 'checked_out';

          // Also check shift data for today's attendance
          final todayShiftAttendance = _getTodayAttendanceFromShiftData();
          bool isCheckedInFromShift = todayShiftAttendance != null;
          bool isCheckedOutFromShift =
              todayShiftAttendance?['checkOutAt'] != null;

          bool hasApiRecord =
              _attendanceStatus != null && _attendanceStatus!['record'] != null;
          bool hasShiftRecord = todayShiftAttendance != null;

          // Always trust API data over local data - if API says no attendance, show no attendance
          final finalHasCheckedIn = hasApiRecord
              ? isCheckedInFromAPI
              : hasShiftRecord
              ? isCheckedInFromShift
              : false; // No API attendance data = not checked in

          final finalHasCheckedOut = hasApiRecord
              ? isCheckedOutFromAPI
              : hasShiftRecord
              ? isCheckedOutFromShift
              : false; // No API attendance data = not checked out

          print('🔍 Attendance Status Debug:');
          print('  - hasApiRecord: $hasApiRecord');
          print('  - hasShiftRecord: $hasShiftRecord');
          print('  - isCheckedInFromAPI: $isCheckedInFromAPI');
          print('  - isCheckedInFromShift: $isCheckedInFromShift');
          print('  - isCheckedOutFromAPI: $isCheckedOutFromAPI');
          print('  - isCheckedOutFromShift: $isCheckedOutFromShift');
          print('  - finalHasCheckedIn: $finalHasCheckedIn');
          print('  - finalHasCheckedOut: $finalHasCheckedOut');

          String? checkInTime;
          String? checkOutTime;

          // Priority 1: Use attendance status API data
          if (_attendanceStatus != null &&
              _attendanceStatus!['record'] != null) {
            final record = _attendanceStatus!['record'];
            checkInTime = record['checkInAt']?.toString();
            checkOutTime = record['checkOutAt']?.toString();
          }

          // Priority 2: Use shift data attendance times
          if (checkInTime == null && todayShiftAttendance != null) {
            checkInTime = todayShiftAttendance['checkInAt']?.toString();
            checkOutTime = todayShiftAttendance['checkOutAt']?.toString();
          }

          // No fallback to local data - only use API data

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
      // If location not loaded yet, try to get it now
      if (_currentLocation == null && !_isLoadingLocation) {
        await _loadCurrentLocation();
      }

      // First, determine if this is a check-in or check-out
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        throw Exception('No employee ID found');
      }

      // Use existing employee profile data from shift data or fallback to API
      Map<String, dynamic> employeeProfile;
      if (_employeeProfile != null) {
        employeeProfile = _employeeProfile!;
      } else {
        final profileResponse = await authService.getEmployeeProfile();
        if (profileResponse['success'] != true) {
          throw Exception('Failed to get employee profile');
        }
        employeeProfile = profileResponse['employee'];
      }
      final employeeData = {
        'fullName':
            '${employeeProfile['firstName'] ?? ''} ${employeeProfile['lastName'] ?? ''}'
                .trim(),
        'positionName': employeeProfile['positionName'] ?? '',
        'companyName': employeeProfile['companyName'] ?? '',
        'locationName': employeeProfile['locationName'] ?? '',
        'branchName': employeeProfile['branchName'] ?? '',
      };

      // Check current status using API attendance data directly
      bool isCheckOut = false;

      // Use the same logic as button state - check actual attendance data
      final attendanceData = _shiftData?['attendanceData'] as List?;
      if (attendanceData?.isNotEmpty == true) {
        final latestRecord = attendanceData!.first;
        final hasCheckedIn = latestRecord['checkInAt'] != null;
        final hasCheckedOut = latestRecord['checkOutAt'] != null;

        if (hasCheckedIn && !hasCheckedOut) {
          isCheckOut = true; // Can check out
        } else if (hasCheckedIn && hasCheckedOut) {
          throw Exception('You have already checked out today');
        }
        // If !hasCheckedIn, isCheckOut remains false (can check in)
      }

      // Use pre-loaded location or navigate to confirmation screen to get it
      Map<String, dynamic>? result;

      if (_currentLocation != null) {
        // Location already available, show quick confirmation
        if (context.mounted) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckInConfirmationScreen(
                employeeData: employeeData,
                isCheckOut: isCheckOut,
              ),
            ),
          );
        }
      } else {
        // Location not available, confirmation screen will get it
        if (context.mounted) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckInConfirmationScreen(
                employeeData: employeeData,
                isCheckOut: isCheckOut,
              ),
            ),
          );
        }
      }

      // If user confirmed, proceed with check-in/out
      if (result != null && result['confirmed'] == true) {
        final latitude = result['latitude'] as double?;
        final longitude = result['longitude'] as double?;
        final address = result['address'] as String?;

        if (isCheckOut) {
          await controller.checkOut(
            employeeData,
            latitude: latitude,
            longitude: longitude,
            address: address,
          );
        } else {
          await controller.checkIn(
            employeeData,
            latitude: latitude,
            longitude: longitude,
            address: address,
          );
        }

        // Refresh attendance status after successful action
        await _refreshAttendanceStatus();

        // Also refresh the attendance controller to get latest data
        ref.invalidate(attendanceControllerProvider);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCheckOut
                    ? 'Checked out successfully!'
                    : 'Checked in successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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

  String _getWorkingHoursDisplay() {
    print('🔍 Debug Working Hours:');
    print('  - _shiftData: $_shiftData');

    if (_shiftData != null && _shiftData!['shiftData'] != null) {
      final shiftDataList = _shiftData!['shiftData'] as List;
      print('  - shiftDataList: $shiftDataList');
      print('  - shiftDataList.length: ${shiftDataList.length}');

      if (shiftDataList.isNotEmpty) {
        final shift = shiftDataList.first;
        final startTime = shift['startTime'];
        final endTime = shift['endTime'];
        print('  - startTime: $startTime');
        print('  - endTime: $endTime');
        return 'Working Hours: $startTime - $endTime';
      } else {
        print('  - shiftDataList is empty');
      }
    } else {
      print('  - _shiftData is null or shiftData key is null');
    }

    return 'Working Hours: Not Available'; // No fallback - use only API data
  }

  Map<String, dynamic>? _getTodayAttendanceFromShiftData() {
    if (_shiftData != null && _shiftData!['attendanceData'] != null) {
      final attendanceDataList = _shiftData!['attendanceData'] as List;
      if (attendanceDataList.isNotEmpty) {
        return attendanceDataList.first;
      }
    }
    return null;
  }

  Map<String, dynamic>? _getEmployeeFromShiftData() {
    if (_shiftData != null && _shiftData!['employee'] != null) {
      return _shiftData!['employee'] as Map<String, dynamic>;
    }
    return null;
  }

  String? _getEmployeeName() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    if (employeeProfile != null) {
      final firstName = employeeProfile['firstName'];
      final lastName = employeeProfile['lastName'];
      if (firstName != null && lastName != null) {
        return '$firstName $lastName';
      }
    }
    return null; // No manual fallback - only use API data
  }

  Widget _buildProfileImage() {
    // Try to get profile image from employee profile or shift data
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    final profileImageUrl = employeeProfile?['profileImage'];

    print('🖼️ Profile Image Debug:');
    print('  - employeeProfile: $employeeProfile');
    print('  - profileImageUrl: $profileImageUrl');

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return Image.network(
        profileImageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        cacheWidth: 100,
        cacheHeight: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildProfileImageFallback();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildProfileImageFallback();
        },
      );
    } else {
      return _buildProfileImageFallback();
    }
  }

  Widget _buildProfileImageWithStoredData() {
    return FutureBuilder<String?>(
      future: _getStoredProfileImageUrl(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return Image.network(
            snapshot.data!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            cacheWidth: 100,
            cacheHeight: 100,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildProfileImageFallback();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildProfileImageFallback();
            },
          );
        }
        return _buildProfileImageFallback();
      },
    );
  }

  Future<String?> _getStoredProfileImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_profile_image');
    } catch (e) {
      print('❌ Error getting stored profile image: $e');
      return null;
    }
  }

  Widget _buildProfileImageFallback() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    final firstName = employeeProfile?['firstName'];
    final lastName = employeeProfile?['lastName'];

    // Only create initials if we have real data
    String initials = '?';
    if (firstName != null && lastName != null) {
      initials = '${firstName[0]}${lastName[0]}'.toUpperCase();
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getLocationDisplayText() {
    // If we have GPS location, find the nearest branch
    if (_currentLocation != null) {
      final latitude = _currentLocation!['latitude'] as double;
      final longitude = _currentLocation!['longitude'] as double;

      // Find nearest branch
      final nearestBranchInfo = BranchLocationService.getNearestBranchInfo(
        latitude,
        longitude,
      );

      if (nearestBranchInfo != null) {
        final branchName = nearestBranchInfo['branchName'] as String;

        // Show only branch name (without distance)
        return branchName;
      }

      // If outside branch radius, show the actual address from reverse geocoding
      final address = _currentLocation!['address'] as String?;
      if (address != null && address.isNotEmpty) {
        return address; // Show full address when not near any branch
      }

      // Last resort fallback - show "Detecting location..."
      return 'Detecting location...';
    }

    // Fallback to profile location if no GPS data
    final shiftEmployee = _getEmployeeFromShiftData();
    return '${_employeeProfile?['companyName'] ?? shiftEmployee?['companyName'] ?? 'NANO-STORES'} - ${_employeeProfile?['locationName'] ?? shiftEmployee?['locationName'] ?? 'Office'}';
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
                'View Attendance History',
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
      height: 300,
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(attendanceControllerProvider);
                await _refreshAttendanceStatus();
              },
              color: AppTheme.kNanoGold,
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
                    cacheExtent: 200,
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
                                a.checkOutAt == null
                                    ? Icons.login
                                    : Icons.logout,
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
                loading: () => const Center(
                  child: Column(
                    children: [SkeletonCard(), SkeletonCard(), SkeletonCard()],
                  ),
                ),
                error: (error, stackTrace) => ErrorStateWidget(
                  message:
                      'Failed to load attendance records. Please check your connection and try again.',
                  actionText: 'Retry',
                  onAction: () => _refreshAttendance(ref),
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
                // Date and Status
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
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getAttendanceStatus(entry),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Check In time
                ...[
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
                    Expanded(
                      child: Text(
                        'Location: ${entry.location}',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
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

  String _getAttendanceStatus(Attendance entry) {
    if (entry.status != null && entry.status!.isNotEmpty) {
      return _formatStatusText(entry.status!);
    }
    return 'Unknown';
  }

  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'late':
        return 'Late';
      case 'on_time':
      case 'ontime':
        return 'On Time';
      case 'early':
        return 'Early';
      case 'in_time':
        return 'In Time';
      default:
        return status;
    }
  }

  Color _getStatusColor(Attendance entry) {
    final status = _getAttendanceStatus(entry);

    switch (status) {
      case 'On Time':
        return Colors.green;
      case 'In Time':
        return Colors.orange;
      case 'Late':
        return Colors.red;
      case 'Early':
        return Colors.blue;

      default:
        return Colors.grey;
    }
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
