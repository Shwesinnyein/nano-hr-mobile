import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_hr_mobile/features/attendance/data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/animated_fade_in.dart';
import 'package:intl/intl.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/branch_location_service.dart';
import '../../../core/widgets/google_map_widget.dart';
import '../../../core/widgets/location_details_modal.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/providers/language_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showDetails = false;
  Map<String, dynamic>? _employeeProfile;
  Map<String, dynamic>? _attendanceStatus;
  Map<String, dynamic>? _apiStatusResponse; // Store API status response with canCheckIn/canCheckOut
  Map<String, dynamic>? _shiftData;
  Map<String, dynamic>? _yesterdayShiftData; // For night shifts that cross midnight
  bool _isLoadingStatus = false;

  final LocationService _locationService = LocationService();
  Map<String, dynamic>? _currentLocation;
  bool _isLoadingLocation = false;
  bool _locationPermissionDenied = false;

  bool _isModalLoading = false;

  Map<String, dynamic>? _cachedButtonState;
  DateTime? _lastButtonStateUpdate;
  static const Duration _buttonStateCacheTimeout = Duration(seconds: 30);

  String fmt(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
  
  String fmtDate(DateTime dt) {
    final isThai = ref.watch(languageProvider);
    if (isThai) {
      final day = dt.day.toString().padLeft(2, '0');
      final monthsThai = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 
                         'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
      final month = monthsThai[dt.month - 1];
      final year = (dt.year + 543).toString(); 
      return '$day $month $year';
    }
    return DateFormat('MMM dd, yyyy').format(dt.toLocal());
  }
  
  String fmtFull(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());

  Map<String, dynamic> _getButtonState(List<Attendance> entries) {
    if (_cachedButtonState != null &&
        _lastButtonStateUpdate != null &&
        DateTime.now().difference(_lastButtonStateUpdate!) <
            _buttonStateCacheTimeout) {
      return _cachedButtonState!;
    }

    // Use API status response if available (preferred method)
    if (_apiStatusResponse != null && _apiStatusResponse!['success'] == true) {
      final canCheckIn = _apiStatusResponse!['canCheckIn'] == true;
      final canCheckOut = _apiStatusResponse!['canCheckOut'] == true;
      final status = _apiStatusResponse!['status']?.toString() ?? '';
      final buttonTextFromApi = _apiStatusResponse!['buttonText']?.toString();
      final action = _apiStatusResponse!['action']?.toString() ?? '';

      String buttonText;
      IconData buttonIcon;
      List<Color> buttonColors;
      bool isEnabled;

      // Handle "checked_in_previous_day" status for overnight workers
      if (status == 'checked_in_previous_day') {
        buttonText = ref.t('ออกงาน', 'Check Out');
        buttonIcon = Icons.logout;
        buttonColors = [AppTheme.kNanoGoldDark, AppTheme.kNanoGold];
        isEnabled = true;
      } else if (canCheckIn) {
        buttonText = buttonTextFromApi ?? ref.t('เข้างาน', 'Check In');
        buttonIcon = Icons.login;
        buttonColors = [AppTheme.kNanoGold, AppTheme.kNanoGoldDark];
        isEnabled = true;
      } else if (canCheckOut) {
        buttonText = buttonTextFromApi ?? ref.t('ออกงาน', 'Check Out');
        buttonIcon = Icons.logout;
        buttonColors = [AppTheme.kNanoGoldDark, AppTheme.kNanoGold];
        isEnabled = true;
      } else {
        // Fallback: check if it's a night shift position
        final bool isNightShift = isNightShiftPosition();
        if (isNightShift && action == 'checkin') {
          // Overnight workers can always check in after checkout
          buttonText = ref.t('เข้างาน', 'Check In');
          buttonIcon = Icons.login;
          buttonColors = [AppTheme.kNanoGold, AppTheme.kNanoGoldDark];
          isEnabled = true;
        } else {
          buttonText = buttonTextFromApi ?? ref.t('ออกงานแล้ว', 'Already Checked Out');
          buttonIcon = Icons.check_circle;
          buttonColors = [Colors.grey, Colors.grey.shade600];
          isEnabled = false;
        }
      }

      final buttonState = {
        'text': buttonText,
        'icon': buttonIcon,
        'colors': buttonColors,
        'enabled': isEnabled,
      };

      _cachedButtonState = buttonState;
      _lastButtonStateUpdate = DateTime.now();

      return buttonState;
    }

    // Fallback: Use local logic if API response not available
    final attendanceData = _shiftData?['attendanceData'] as List?;
    final latestRecord = attendanceData?.isNotEmpty == true
        ? attendanceData!.first
        : null;
    
    // Check yesterday's attendance for night shifts (e.g., 22:00 - 06:00)
    // Only for Driver and Security positions
    // If today has no open attendance, check yesterday
    Map<String, dynamic>? activeRecord = latestRecord;
    if (isNightShiftPosition() && 
        (latestRecord == null || 
         (latestRecord['checkInAt'] != null && latestRecord['checkOutAt'] != null))) {
      // No open attendance today, check yesterday (only for Driver/Security)
      final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
      if (yesterdayAttendanceData?.isNotEmpty == true) {
        final yesterdayRecord = yesterdayAttendanceData!.first;
        // If yesterday has check-in but no check-out, use that record
        if (yesterdayRecord['checkInAt'] != null && 
            yesterdayRecord['checkOutAt'] == null) {
          activeRecord = yesterdayRecord;
        }
      }
    }
    
    final hasCheckedIn = activeRecord?['checkInAt'] != null;
    final hasCheckedOut = activeRecord?['checkOutAt'] != null;
    
    // For Driver and Security: Always allow check-in/out (no restrictions)
    // They can check in multiple times per day and check out anytime
    final bool isNightShift = isNightShiftPosition();
    
    // Allow check-in if:
    // 1. No check-in record exists, OR
    // 2. The active record is fully checked out (both check-in and check-out exist)
    // For night shift workers: always allow check-in after checkout
    final bool canCheckIn = !hasCheckedIn || (hasCheckedIn && hasCheckedOut);
    final bool canCheckOut = hasCheckedIn && !hasCheckedOut;

    String buttonText;
    IconData buttonIcon;
    List<Color> buttonColors;
    bool isEnabled;

    if (canCheckIn) {
      buttonText = ref.t('เข้างาน', 'Check In');
      buttonIcon = Icons.login;
      buttonColors = [AppTheme.kNanoGold, AppTheme.kNanoGoldDark];
      isEnabled = true;
    } else if (canCheckOut) {
      buttonText = ref.t('ออกงาน', 'Check Out');
      buttonIcon = Icons.logout;
      buttonColors = [AppTheme.kNanoGoldDark, AppTheme.kNanoGold];
      isEnabled = true;
    } else {
      // For Driver/Security: Never show disabled "Already Checked Out"
      // Always allow them to check in again
      if (isNightShift) {
        buttonText = ref.t('เข้างาน', 'Check In');
        buttonIcon = Icons.login;
        buttonColors = [AppTheme.kNanoGold, AppTheme.kNanoGoldDark];
        isEnabled = true;
      } else {
        // For other positions: show disabled state if already checked out
        buttonText = ref.t('ออกงานแล้ว', 'Already Checked Out');
        buttonIcon = Icons.check_circle;
        buttonColors = [Colors.grey, Colors.grey.shade600];
        isEnabled = false;
      }
    }

    final buttonState = {
      'text': buttonText,
      'icon': buttonIcon,
      'colors': buttonColors,
      'enabled': isEnabled,
    };

    _cachedButtonState = buttonState;
    _lastButtonStateUpdate = DateTime.now();

    return buttonState;
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
    if (_employeeProfile != null &&
        _attendanceStatus != null &&
        _shiftData != null) {
      return;
    }

    try {
      final loadStartTime = DateTime.now();
      if (kDebugMode) {
        debugPrint('⏱️ [Attendance] Starting data load');
      }
      
      setState(() {
        _isLoadingStatus = true;
      });

      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        setState(() { 
          _isLoadingStatus = false;
        });
        return;
      }

      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final attendanceService = ref.read(attendanceServiceProvider);
      
      // OPTIMIZATION: Run API calls in parallel instead of sequential
      // Fetch today's attendance data and status in parallel
      final apiStartTime = DateTime.now();
      final results = await Future.wait([
        apiService.getShiftDataWithFilter(
          employeeId: employeeId,
          date: dateString,
        ),
        attendanceService.getTodayAttendanceStatus(
          employeeId: employeeId,
        ),
      ]);
      final apiDuration = DateTime.now().difference(apiStartTime);
      if (kDebugMode) {
        debugPrint('⏱️ [Attendance] Parallel API calls took: ${apiDuration.inMilliseconds}ms');
      }

      final shiftDataResponse = results[0] as Map<String, dynamic>;
      final statusResponse = results[1] as Map<String, dynamic>;

      // Check if employee is Driver or Security from the shift data response
      bool shouldCheckYesterday = false;
      if (shiftDataResponse['success'] == true && shiftDataResponse['employee'] != null) {
        final employee = shiftDataResponse['employee'] as Map<String, dynamic>;
        final positionName = (employee['positionName'] ?? employee['position'] ?? '').toString().toLowerCase();
        shouldCheckYesterday = positionName.contains('driver') || positionName.contains('security');
      } else if (_employeeProfile != null) {
        // Fallback to existing profile if available
        shouldCheckYesterday = isNightShiftPosition();
      }

      // Also check yesterday for night shifts that cross midnight (only for Driver/Security)
      Map<String, dynamic>? yesterdayShiftDataResponse;
      if (shouldCheckYesterday) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayDateString =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        yesterdayShiftDataResponse = await apiService.getShiftDataWithFilter(
          employeeId: employeeId,
          date: yesterdayDateString,
        );
      }

      if (mounted) {
        setState(() {
          if (shiftDataResponse['success'] == true) {
            _shiftData = shiftDataResponse;

            if (_shiftData?['employee'] != null) {
              _employeeProfile = _shiftData!['employee'];
            }

            // Store yesterday's data for night shift handling (only for Driver/Security)
            if (yesterdayShiftDataResponse != null && yesterdayShiftDataResponse['success'] == true) {
              _yesterdayShiftData = yesterdayShiftDataResponse;
            }

            // Store API status response for button logic
            _apiStatusResponse = statusResponse;

            // Determine active record (today's or yesterday's if not checked out)
            Map<String, dynamic>? activeRecord;
            final todayAttendanceData = _shiftData?['attendanceData'] as List?;
            if (todayAttendanceData?.isNotEmpty == true) {
              final todayRecord = todayAttendanceData!.first;
              if (todayRecord['checkInAt'] != null && 
                  todayRecord['checkOutAt'] == null) {
                activeRecord = todayRecord;
              }
            }
            
            // If no open attendance today, check yesterday (only for Driver/Security night shifts)
            if (activeRecord == null && isNightShiftPosition() && _yesterdayShiftData != null) {
              final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
              if (yesterdayAttendanceData?.isNotEmpty == true) {
                final yesterdayRecord = yesterdayAttendanceData!.first;
                if (yesterdayRecord['checkInAt'] != null && 
                    yesterdayRecord['checkOutAt'] == null) {
                  activeRecord = yesterdayRecord;
                }
              }
            }

            if (_shiftData?['attendanceData'] != null || activeRecord != null) {
              _attendanceStatus = {
                'success': true,
                'data': _shiftData?['attendanceData'] ?? [],
                'record': activeRecord ?? (_shiftData?['attendanceData']?.isNotEmpty == true
                    ? _shiftData!['attendanceData'][0]
                    : null),
              };
            }

            _cachedButtonState = null;
            _lastButtonStateUpdate = null;
          }
          _isLoadingStatus = false;
        });
        
        final totalLoadDuration = DateTime.now().difference(loadStartTime);
        if (kDebugMode) {
          debugPrint('⏱️ [Attendance] Total data load time: ${totalLoadDuration.inMilliseconds}ms');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
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
      _locationPermissionDenied = false;
    });

    try {
      final hasPermission = await _locationService.checkPermissions();
      
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionDenied = true;
            _currentLocation = null;
          });
          _showLocationPermissionWarning(context);
        }
        return;
      }

      final locationData =
          await _locationService.getCurrentLocationWithAddress();

      if (kDebugMode) {
        final latitude = locationData['latitude'] as double?;
        final longitude = locationData['longitude'] as double?;
        final address = locationData['address'];

        if (latitude != null && longitude != null) {
          final nearestBranch = BranchLocationService.findNearestBranch(
            latitude,
            longitude,
            enforceRadius: false,
          );
          double? distanceKm;
          String branchName = 'Unknown';

          if (nearestBranch != null) {
            branchName = nearestBranch.branchName;
            distanceKm = BranchLocationService.calculateDistance(
              latitude,
              longitude,
              nearestBranch.latitude,
              nearestBranch.longitude,
            );
          }

          final withinRadius = distanceKm != null &&
              distanceKm <= BranchLocationService.maxBranchRadius;

         
        }
      }

      if (mounted) {
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
          _locationPermissionDenied = false;
        });
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      final isPermissionError = errorMessage.contains('permission') || 
                                errorMessage.contains('denied') ||
                                errorMessage.contains('location');
      
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          if (isPermissionError) {
            _locationPermissionDenied = true;
            _currentLocation = null;
            _showLocationPermissionWarning(context);
          }
        });
      }
    }
  }

  void _showLocationPermissionWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_off,
                color: AppTheme.errorColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ref.t('ต้องการสิทธิ์เข้าถึงตำแหน่ง', 'Location Permission Required'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.t(
                  'แอป NANO Work ต้องการสิทธิ์เข้าถึงตำแหน่งที่ตั้งเพื่อบันทึกตำแหน่งในการเช็คอิน/เช็คเอาท์',
                  'NANO Work app needs location permission to record your location for check-in/check-out.',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.kNanoGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ref.t(
                          'คุณจะไม่สามารถเช็คอิน/เช็คเอาท์ได้หากไม่ให้สิทธิ์',
                          'You cannot check in/out without location permission.',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.kNanoGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                ref.t('ยกเลิก', 'Cancel'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _locationService.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kNanoGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                ref.t('ไปที่การตั้งค่า', 'Open Settings'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshAttendanceStatus() async {
    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) return;

      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Fetch today's attendance data first to get employee profile
      final response = await apiService.getShiftDataWithFilter(
        employeeId: employeeId,
        date: dateString,
      );

      // Check if employee is Driver or Security from the response
      bool shouldCheckYesterday = false;
      if (response['success'] == true && response['employee'] != null) {
        final employee = response['employee'] as Map<String, dynamic>;
        final positionName = (employee['positionName'] ?? employee['position'] ?? '').toString().toLowerCase();
        shouldCheckYesterday = positionName.contains('driver') || positionName.contains('security');
      } else if (_employeeProfile != null) {
        // Fallback to existing profile if available
        shouldCheckYesterday = isNightShiftPosition();
      }

      // Also check yesterday for night shifts that cross midnight (only for Driver/Security)
      Map<String, dynamic>? yesterdayResponse;
      if (shouldCheckYesterday) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayDateString =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        yesterdayResponse = await apiService.getShiftDataWithFilter(
          employeeId: employeeId,
          date: yesterdayDateString,
        );
      }

      // Fetch API status response (includes canCheckIn, canCheckOut, status, etc.)
      final attendanceService = ref.read(attendanceServiceProvider);
      final statusResponse = await attendanceService.getTodayAttendanceStatus(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        setState(() {
          _shiftData = response;

          // Store API status response for button logic
          _apiStatusResponse = statusResponse;

          // Store yesterday's data for night shift handling (only for Driver/Security)
          if (yesterdayResponse != null && yesterdayResponse['success'] == true) {
            _yesterdayShiftData = yesterdayResponse;
          }

          if (_shiftData?['employee'] != null) {
            _employeeProfile = _shiftData!['employee'];
          }

          // Determine active record (today's or yesterday's if not checked out)
          Map<String, dynamic>? activeRecord;
          final todayAttendanceData = _shiftData?['attendanceData'] as List?;
          if (todayAttendanceData != null && todayAttendanceData.isNotEmpty) {
            final todayRecord = todayAttendanceData[0] as Map<String, dynamic>;
            if (todayRecord['checkInAt'] != null && 
                todayRecord['checkOutAt'] == null) {
              activeRecord = todayRecord;
            }
          }
          
          // If no open attendance today, check yesterday (only for Driver/Security night shifts)
          if (activeRecord == null && isNightShiftPosition() && _yesterdayShiftData != null) {
            final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
            if (yesterdayAttendanceData != null && yesterdayAttendanceData.isNotEmpty) {
              final yesterdayRecord = yesterdayAttendanceData[0] as Map<String, dynamic>;
              if (yesterdayRecord['checkInAt'] != null && 
                  yesterdayRecord['checkOutAt'] == null) {
                activeRecord = yesterdayRecord;
              }
            }
          }

          if (_shiftData?['attendanceData'] != null || activeRecord != null) {
            final attendanceData = _shiftData?['attendanceData'] ?? [];
            final latestRecord = activeRecord ?? (attendanceData.isNotEmpty ? attendanceData[0] : null);

            String status = 'not_checked_in';
            if (latestRecord != null) {
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
          }

          _cachedButtonState = null;
          _lastButtonStateUpdate = null;
        });
      }
    } catch (e) {
    }
  }

    Future<List<Attendance>> _loadAttendanceHistory() async {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
              const SizedBox(height: 16),
              Text(
                ref.t('กำลังโหลดข้อมูลการเข้างาน...', 'Loading attendance data...'),
                style: const TextStyle(
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

    return Scaffold(
      backgroundColor: AppTheme.kNanoGold, 
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top,
            color: AppTheme.kNanoGold, 
          ),
          Expanded(
            child: Container(
              color: AppTheme.kBackground,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
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
                    // Add bottom padding to ensure buttons are always accessible
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.t('สวัสดี!', 'Have a nice day!'),
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
              IconButton(
                onPressed: () async {
                  ref.invalidate(attendanceControllerProvider);
                  await _refreshAttendanceStatus();
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: ref.t('รีเฟรช', 'Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            ref.t('วันนี้', 'Today'),
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
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getLocationDisplayText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 20),
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
          ref.t('เกิดข้อผิดพลาดในการโหลดข้อมูลการเข้างาน', 'Error loading attendance data'),
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
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: state.when(
        data: (entries) {
          // Get active record (today's or yesterday's if not checked out)
          Map<String, dynamic>? activeRecord;
          final attendanceData = _shiftData?['attendanceData'] as List?;
          if (attendanceData?.isNotEmpty == true) {
            final todayRecord = attendanceData!.first;
            if (todayRecord['checkInAt'] != null && 
                todayRecord['checkOutAt'] == null) {
              activeRecord = todayRecord;
            }
          }
          
          // If no open attendance today, check yesterday for night shifts (only for Driver/Security)
          if (activeRecord == null && isNightShiftPosition() && _yesterdayShiftData != null) {
            final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
            if (yesterdayAttendanceData?.isNotEmpty == true) {
              final yesterdayRecord = yesterdayAttendanceData!.first;
              if (yesterdayRecord['checkInAt'] != null && 
                  yesterdayRecord['checkOutAt'] == null) {
                activeRecord = yesterdayRecord;
              }
            }
          }
          
          // Fallback to today's latest record if no active record found
          final latestRecord = activeRecord ?? (attendanceData?.isNotEmpty == true
              ? attendanceData!.first
              : null);

          final hasCheckedIn = latestRecord?['checkInAt'] != null;
          final hasCheckedOut = latestRecord?['checkOutAt'] != null;

          final checkInTime = latestRecord?['checkInAt']?.toString();
          final checkOutTime = latestRecord?['checkOutAt']?.toString();
          final checkInDate = latestRecord?['checkInDate']?.toString();
          final checkOutDate = latestRecord?['checkOutDate']?.toString();
          final isOvernightShift = latestRecord?['isOvernightShift'] == true || 
              latestRecord?['isOvernightShift'] == 'true' ||
              (checkInDate != null && checkOutDate != null && checkInDate != checkOutDate);

          // Format date for display
          String formatDateForDisplay(String? dateStr) {
            if (dateStr == null) return '';
            try {
              final date = DateTime.parse(dateStr);
              return fmtDate(date);
            } catch (e) {
              return dateStr;
            }
          }

          // Format time for display (extract time from datetime string)
          String formatTimeForDisplay(String? timeStr) {
            if (timeStr == null) return '';
            try {
              if (timeStr.contains('T')) {
                final dateTime = DateTime.parse(timeStr);
                return fmt(dateTime);
              } else if (timeStr.contains(':')) {
                // Already a time string (HH:mm:ss)
                return timeStr.split('.').first; // Remove milliseconds if present
              }
              return timeStr;
            } catch (e) {
              return timeStr;
            }
          }

          return Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasCheckedIn && !hasCheckedOut
                      ? Icons.login
                      : hasCheckedIn && hasCheckedOut
                      ? Icons.logout
                      : Icons.access_time,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                checkInTime != null && checkOutTime != null
                    ? ref.t('ออกงานแล้ว', 'Checked Out')
                    : checkInTime != null
                    ? ref.t('เข้างานแล้ว', 'Checked In')
                    : ref.t('ยังไม่ได้เข้างาน', 'Not Checked In'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOvernightShift) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref.t('กะข้ามคืน', 'Overnight Shift'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (checkInTime != null) ...[
                if (checkOutTime != null) ...[
                  // Both check-in and check-out: display side by side
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Check-in on the left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ref.t('เข้างาน', 'Check In'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTimeForDisplay(checkInTime),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (checkInDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                formatDateForDisplay(checkInDate),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Divider in the middle
                      Container(
                        width: 1,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      // Check-out on the right
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ref.t('ออกงาน', 'Check Out'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTimeForDisplay(checkOutTime),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (checkOutDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                formatDateForDisplay(checkOutDate),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Only check-in: display centered
                  Column(
                    children: [
                      Text(
                        '${ref.t('เข้างาน', 'Check In')}: ${formatTimeForDisplay(checkInTime)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      if (checkInDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatDateForDisplay(checkInDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                ref.t('กำลังโหลดข้อมูลการเข้างาน...', 'Loading attendance...'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 40),
            const SizedBox(height: 16),
            Text(
              ref.t('เกิดข้อผิดพลาดในการโหลดข้อมูล', 'Error loading status'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.t('แตะเพื่อลองใหม่', 'Tap to retry'),
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

  /// Checks if the employee position requires night shift handling (crosses midnight)
  /// Only Driver and Security positions need to check yesterday's attendance
  bool isNightShiftPosition() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    if (employeeProfile == null) {
      return false;
    }

    final positionName = (employeeProfile['positionName'] ?? employeeProfile['position'] ?? '').toString().toLowerCase();
    
    // Only Driver and Security positions have night shifts that cross midnight
    return positionName.contains('driver') || positionName.contains('security');
  }

  /// Determines if location restriction should be enforced based on company and position
  /// 
  /// Rules:
  /// - nanovip company → No restriction (can check in/out everywhere)
  /// - nanostore company + office position → No restriction (can check in/out everywhere)
  /// - branch name contains "office" → No restriction (can check in/out everywhere)
  /// - nanostore company + non-office position → Restriction (must be in branch area)
  /// - BranchLocation company → Restriction (must be in branch area)
  /// - Default → Restriction (must be in branch area) for safety
  bool shouldEnforceLocationRestriction() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    if (employeeProfile == null) {
      // Default to enforcing restriction for safety
      return true;
    }

    final companyName = (employeeProfile['companyName'] ?? employeeProfile['company'] ?? '').toString().toLowerCase();
    final positionName = (employeeProfile['positionName'] ?? employeeProfile['position'] ?? '').toString().toLowerCase();
    final branchName = (employeeProfile['branchName'] ?? employeeProfile['branch'] ?? '').toString().toLowerCase();

    // nanovip employees can check in/out everywhere (no restriction)
    if (companyName.contains('nanovip') || companyName.contains('nano-vip')) {
      return false;
    }

    // nanostore office employees can check in/out everywhere (no restriction)
    if ((companyName.contains('nanostore') || companyName.contains('nano-store')) && 
        positionName.contains('office')) {
      return false;
    }

    // If branch name contains "office", allow check in/out everywhere (no restriction)
    if (branchName.contains('office')) {
      return false;
    }

    // BranchLocation employees and nanostore non-office employees must be in office area
    // Default: enforce restriction for safety
    return true;
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
          final buttonState = _getButtonState(entries);
          final shouldEnforce = shouldEnforceLocationRestriction();
          
          // Always check if within branch radius (for display purposes)
          bool withinBranch = false;
          String? nearestBranchName;
          if (_currentLocation != null) {
            final lat = _currentLocation!['latitude'] as double?;
            final lng = _currentLocation!['longitude'] as double?;
            if (lat != null && lng != null) {
              withinBranch = BranchLocationService.isWithinBranchRadius(lat, lng);
              // Get nearest branch info for display
              final nearestBranchInfo = BranchLocationService.getNearestBranchInfo(lat, lng);
              if (nearestBranchInfo != null) {
                nearestBranchName = nearestBranchInfo['branchName'] as String?;
              }
            }
          }

          // If no restriction needed, consider it as within branch for button enablement
          // But still show branch info if available
          final isEnabled = shouldEnforce
              ? ((buttonState['enabled'] as bool) && withinBranch)
              : (buttonState['enabled'] as bool);
          
          // Build display text
          String displayText;
          if (shouldEnforce && !withinBranch) {
            // Restriction enforced but outside area
            displayText = ref.t('นอกพื้นที่สำนักงาน', 'Outside office area');
          } else if (!shouldEnforce && withinBranch && nearestBranchName != null) {
            // No restriction but within branch - show branch name
            displayText = '${buttonState['text'] as String} - $nearestBranchName';
          } else if (!shouldEnforce && !withinBranch && nearestBranchName != null) {
            // No restriction, outside branch but show nearest branch
            displayText = '${buttonState['text'] as String} (Near: $nearestBranchName)';
          } else {
            // Default: just show button text
            displayText = buttonState['text'] as String;
          }

          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: buttonState['colors']),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kNanoGold.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () => _handleCheckInOut(context, ref, controller)
                  : null, 
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
                    displayText,
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
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        throw Exception('No employee ID found');
      }

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

      bool isCheckOut = false;
      Map<String, dynamic>? activeRecord;

      // Check today's attendance first
      final attendanceData = _shiftData?['attendanceData'] as List?;
      if (attendanceData?.isNotEmpty == true) {
        final latestRecord = attendanceData!.first;
        final hasCheckedIn = latestRecord['checkInAt'] != null;
        final hasCheckedOut = latestRecord['checkOutAt'] != null;

        if (hasCheckedIn && !hasCheckedOut) {
          isCheckOut = true;
          activeRecord = latestRecord;
        } else if (hasCheckedIn && hasCheckedOut) {
          // Today is already checked out, check if yesterday has open attendance (only for Driver/Security)
          if (isNightShiftPosition()) {
            final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
            if (yesterdayAttendanceData?.isNotEmpty == true) {
              final yesterdayRecord = yesterdayAttendanceData!.first;
              if (yesterdayRecord['checkInAt'] != null && 
                  yesterdayRecord['checkOutAt'] == null) {
                isCheckOut = true;
                activeRecord = yesterdayRecord;
              }
            }
          }
        }
      } else {
        // No attendance today, check yesterday for night shifts (only for Driver/Security)
        if (isNightShiftPosition()) {
          final yesterdayAttendanceData = _yesterdayShiftData?['attendanceData'] as List?;
          if (yesterdayAttendanceData?.isNotEmpty == true) {
            final yesterdayRecord = yesterdayAttendanceData!.first;
            if (yesterdayRecord['checkInAt'] != null && 
                yesterdayRecord['checkOutAt'] == null) {
              isCheckOut = true;
              activeRecord = yesterdayRecord;
            }
          }
        }
      }

      Map<String, dynamic>? result;

      if (context.mounted) {
        result = await _showCheckInOutModal(context, isCheckOut);
      }

      if (result != null && result['confirmed'] == true) {
        final latitude = result['latitude'] as double?;
        final longitude = result['longitude'] as double?;
        final address = result['address'] as String?;

        // Validate location if restriction is enforced
        final shouldEnforce = shouldEnforceLocationRestriction();
        if (shouldEnforce && latitude != null && longitude != null) {
          final withinBranch = BranchLocationService.isWithinBranchRadius(
            latitude,
            longitude,
          );
          if (!withinBranch) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ref.t('นอกพื้นที่สำนักงาน', 'Outside office area'),
                  ),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
            return;
          }
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.kNanoGold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isCheckOut ? ref.t('กำลังออกงาน...', 'Checking out...') : ref.t('กำลังเข้างาน...', 'Checking in...'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        try {
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

          if (context.mounted) {
            Navigator.of(context).pop();
          }

          await _refreshAttendanceStatus();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isCheckOut
                      ? ref.t('ออกงานสำเร็จ!', 'Checked out successfully!')
                      : ref.t('เข้างานสำเร็จ!', 'Checked in successfully!'),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          rethrow;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ref.t('ข้อผิดพลาด', 'Error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: ref.t('ลองอีกครั้ง', 'Retry'),
              textColor: Colors.white,
              onPressed: () => _handleCheckInOut(context, ref, controller),
            ),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showCheckInOutModal(
    BuildContext context,
    bool isCheckOut,
  ) async {
    _isModalLoading = false;

    final currentTime = DateTime.now();
    final timeString = DateFormat('HH:mm').format(currentTime);

    final location = _currentLocation;
    
    String getLocationText() {
      if (location != null) {
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        if (lat != null && lng != null) {
          final nearestBranch = BranchLocationService.findNearestBranch(lat, lng);
          if (nearestBranch != null) {
            return nearestBranch.branchName;
          }
          return location['address'] as String? ?? ref.t('ตำแหน่งปัจจุบัน', 'Current Location');
        }
      }
      return ref.t('กำลังระบุตำแหน่ง...', 'Getting location...');
    }

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckOut ? Icons.logout : Icons.login,
                      size: 48,
                      color: isCheckOut ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      isCheckOut ? ref.t('ออกงาน', 'Check Out') : ref.t('เข้างาน', 'Check In'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${ref.t('เวลา', 'Time')}: $timeString',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              getLocationText(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isModalLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop(null);
                                  },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              ref.t('ยกเลิก', 'Cancel'),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isModalLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop({
                                      'confirmed': true,
                                      'latitude': location?['latitude'],
                                      'longitude': location?['longitude'],
                                      'address':
                                          location?['address'] ??
                                          'Location will be updated',
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isModalLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    isCheckOut ? ref.t('ยืนยันออกงาน', 'Confirm') : ref.t('ยืนยันเข้างาน', 'Confirm'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
      },
    );
  }

  void _refreshAttendance(WidgetRef ref) {
    ref.invalidate(attendanceControllerProvider);
  }

  String _getWorkingHoursDisplay() {
    if (_shiftData != null && _shiftData!['shiftData'] != null) {
      final shiftDataList = _shiftData!['shiftData'] as List;

      if (shiftDataList.isNotEmpty) {
        final shift = shiftDataList.first;
        final startTime = shift['startTime'];
        final endTime = shift['endTime'];

        return '${ref.t('เวลาทำงาน', 'Working Hours')}: $startTime - $endTime';
      } else {
      }
    }

      return '${ref.t('เวลาทำงาน', 'Working Hours')}: ${ref.t('ไม่มีข้อมูล', 'Not Available')}'; 
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
    return null; 
  }

  Widget _buildProfileImage() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    final profileImageUrl = employeeProfile?['profileImage'];

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


  Widget _buildProfileImageFallback() {
    final employeeProfile = _employeeProfile ?? _getEmployeeFromShiftData();
    final firstName = employeeProfile?['firstName'];
    final lastName = employeeProfile?['lastName'];

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
    
    if (_locationPermissionDenied) {
      return ref.t('ไม่สามารถเข้าถึงตำแหน่ง', 'Location not available');
    }
    
    
    if (_isLoadingLocation) {
      return ref.t('กำลังระบุตำแหน่ง...', 'Detecting location...');
    }
    
    if (_currentLocation != null) {
      final latitude = _currentLocation!['latitude'] as double;
      final longitude = _currentLocation!['longitude'] as double;

      final nearestBranchInfo = BranchLocationService.getNearestBranchInfo(
        latitude,
        longitude,
      );

      if (nearestBranchInfo != null) {
        final branchName = nearestBranchInfo['branchName'] as String;
        return branchName;
      }

      final address = _currentLocation!['address'] as String?;
      if (address != null && address.isNotEmpty) {
        return address; 
      }

      return ref.t('กำลังระบุตำแหน่ง...', 'Detecting location...');
    }

    return ref.t('ไม่สามารถเข้าถึงตำแหน่ง', 'Location not available');
  }

  Widget _buildViewDetailsButton(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Attendance>> state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
                  _showDetailedLocationModal(context);
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
                      Icons.location_on,
                      color: AppTheme.kNanoGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ref.t('สถานที่', 'Location'),
                      style: const TextStyle(
                        color: AppTheme.kNanoGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
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
                  context.push('/attendance/calendar');
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
                      ref.t('ดูการเข้างาน', 'Attendance'),
                      style: const TextStyle(
                        color: AppTheme.kNanoGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showLocationInfo(BuildContext context) async {
    await _loadCurrentLocation();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, color: AppTheme.kNanoGold, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      ref.t('ตำแหน่ง GPS', 'GPS Location'),
                      style: const TextStyle(
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
              Expanded(child: _buildMapContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapContent() {
    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              ref.t('ไม่สามารถระบุตำแหน่งได้', 'Location not available'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.t('กรุณาเปิด GPS และลองใหม่อีกครั้ง', 'Please enable GPS and try again'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final latitude = _currentLocation!['latitude'] as double;
    final longitude = _currentLocation!['longitude'] as double;
    final address = _currentLocation!['address'] as String?;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(20),
            child: GoogleMapWidget(
              latitude: latitude,
              longitude: longitude,
              address: address,
              title: 'Your Location',
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.t('รายละเอียดสถานที่', 'Location Details'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNanoGold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLocationDetailRow(
                  '📍',
                  ref.t('ที่อยู่', 'Address'),
                  address ?? ref.t('ไม่มีข้อมูล', 'Not available'),
                ),
                const SizedBox(height: 12),
                _buildLocationDetailRow('🕐', ref.t('อัปเดตล่าสุด', 'Last Updated'), ref.t('เมื่อสักครู่', 'Just now')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailedLocationModal(BuildContext context) async {
    await _loadCurrentLocation();
    
    if (!mounted) return;
    
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final latitude = _currentLocation!['latitude'] as double;
    final longitude = _currentLocation!['longitude'] as double;
    final address = _currentLocation!['address'] as String? ?? 'Address not available';

    final nearestBranch = BranchLocationService.findNearestBranch(latitude, longitude);
    final distance = nearestBranch != null 
        ? BranchLocationService.calculateDistance(
            latitude, longitude, 
            nearestBranch.latitude, nearestBranch.longitude
          )
        : 0.0;
    
    final isWithinRange = distance <= 100; 

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationDetailsModal(
          latitude: latitude,
          longitude: longitude,
          address: address,
          onConfirm: () {
            Navigator.of(context).pop();

          },
        ),
      ),
    );
  }

  Widget _buildLocationDetailRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            ref.t('ไม่มีบันทึกการเข้างาน', 'No attendance records'),
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        future: _loadAttendanceHistory(),
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
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                        ref.t('รายละเอียดการเข้างาน', 'Attendance Details'),
                        style: const TextStyle(
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
            ),
            const SizedBox(height: 16),
            Text(
              ref.t('กำลังโหลดประวัติการเข้างาน...', 'Loading attendance history...'),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
            Text(
              ref.t('เกิดข้อผิดพลาดในการโหลดข้อมูลการเข้างาน', 'Error loading attendance'),
              style: const TextStyle(
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
      return Center(child: Text(ref.t('ไม่มีบันทึกการเข้างาน', 'No attendance records')));
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
                        '${ref.t('เข้างาน', 'Check In')}: ${_formatTimeOnly(entry.checkInAt)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (entry.checkOutAt != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${ref.t('ออกงาน', 'Check Out')}: ${_formatTimeOnly(entry.checkOutAt)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ref.t('สถานที่', 'Location')}: ${entry.location}',
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
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    return dateString;
  }
}

String _formatTimeOnly(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';
  return DateFormat('HH:mm:ss').format(dateTime);
}
