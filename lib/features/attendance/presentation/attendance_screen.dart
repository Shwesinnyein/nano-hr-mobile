import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_hr_mobile/features/attendance/data/attendance_model.dart';
import '../data/attendance_repository.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/services/employee_auth_service.dart';
import '../../../app/theme.dart';
import 'package:intl/intl.dart';
import '../../employee/data/employee_model.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showDetails = false;

  String fmt(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
  String fmtDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy').format(dt.toLocal());
  String fmtFull(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final employeeAuthService = ref.watch(employeeAuthServiceProvider);
    final currentEmployee = employeeAuthService.currentEmployee;

    if (currentEmployee == null) {
      return Container(
        color: AppTheme.kBackground,
        child: const Center(child: Text('Please login first')),
      );
    }

    // Use UID for API calls, fallback to ID if UID is not available
    final employeeId = currentEmployee.uid ?? currentEmployee.id;
    print(
      '🔍 AttendanceScreen: Using employee ID: $employeeId (UID: ${currentEmployee.uid}, ID: ${currentEmployee.id})',
    );

    final controller = ref.read(attendanceControllerProvider.notifier);
    final state = ref.watch(attendanceControllerProvider);

    // Debug: Print the current state
    print('🔍 AttendanceScreen: Current state: $state');
    if (state.hasError) {
      print('❌ AttendanceScreen: Error detected: ${state.error}');
    }

    return Container(
      color: AppTheme.kBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header with today's date and status
            _buildHeader(context, ref, state, currentEmployee),
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
    Employee currentEmployee,
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
                    child: currentEmployee.profileImage != null
                        ? Image.network(
                            currentEmployee.profileImage!,
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
                      'Shwe Sin Nyein',
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
                  '${currentEmployee.companyName ?? 'NANO-STORES'} - ${currentEmployee.locationName ?? 'Office'}',
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
    print('🔍 UI Status Card: State: $state');
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
          print('🔍 UI Status Card: Total entries: ${entries.length}');
          print('🔍 UI Status Card: Entries: $entries');

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

          print('🔍 UI Status Card: Today entries: ${todayEntries.length}');
          if (todayEntries.isNotEmpty) {
            print(
              '🔍 UI Status Card: Latest entry: ${todayEntries.last.checkInAt}',
            );
            print(
              '🔍 UI Status Card: Check out time: ${todayEntries.last.checkOutAt}',
            );
            print(
              '🔍 UI Status Card: Formatted check-in time: ${fmt(todayEntries.last.checkInAt)}',
            );
            if (todayEntries.last.checkOutAt != null) {
              print(
                '🔍 UI Status Card: Formatted check-out time: ${fmt(todayEntries.last.checkOutAt!)}',
              );
            }
          }

          final hasCheckedIn = todayEntries.isNotEmpty;
          final hasCheckedOut =
              todayEntries.isNotEmpty && todayEntries.last.checkOutAt != null;

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
              // Status text
              Text(
                hasCheckedIn && !hasCheckedOut
                    ? 'Checked In'
                    : hasCheckedIn && hasCheckedOut
                    ? 'Checked Out'
                    : 'Not Checked In',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Time display
              if (hasCheckedIn) ...[
                Text(
                  'Check In: ${fmt(todayEntries.last.checkInAt)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (hasCheckedOut) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Check Out: ${fmt(todayEntries.last.checkOutAt!)}',
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

          final hasCheckedIn = todayEntries.isNotEmpty;
          final hasCheckedOut =
              todayEntries.isNotEmpty && todayEntries.last.checkOutAt != null;

          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasCheckedIn && !hasCheckedOut
                    ? [AppTheme.kNanoGoldDark, AppTheme.kNanoGold]
                    : [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
              ),
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
              onPressed: () => _handleCheckInOut(context, ref, controller),
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
                    hasCheckedIn && !hasCheckedOut ? Icons.logout : Icons.login,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasCheckedIn && !hasCheckedOut ? 'Check Out' : 'Check In',
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
          // Header
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     color: AppTheme.kNanoGoldLight.withOpacity(0.3),
          //     borderRadius: const BorderRadius.only(
          //       topLeft: Radius.circular(20),
          //       topRight: Radius.circular(20),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(Icons.history, color: AppTheme.kNanoGold, size: 24),
          //       const SizedBox(width: 12),
          //       Text(
          //         'Recent Attendance',
          //         style: TextStyle(
          //           color: AppTheme.kNanoGold,
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // List
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
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Load attendance history when modal opens
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(attendanceControllerProvider.notifier)
                .loadAttendanceHistory();
          });

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
                Expanded(
                  child: state.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: Text('No attendance records'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: entry.checkOutAt == null
                                    ? AppTheme.kNanoGold.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                child: Icon(
                                  entry.checkOutAt == null
                                      ? Icons.login
                                      : Icons.logout,
                                  color: entry.checkOutAt == null
                                      ? AppTheme.kNanoGold
                                      : Colors.green,
                                ),
                              ),
                              title: Text(fmtFull(entry.checkInAt)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.checkOutAt != null)
                                    Text(
                                      'Check Out: ${fmtFull(entry.checkOutAt!)}',
                                    ),
                                  Text('Location: ${entry.location}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) {
                      return Center(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
