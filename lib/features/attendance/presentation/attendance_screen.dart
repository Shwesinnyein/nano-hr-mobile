import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/attendance_repository.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/services/employee_auth_service.dart';
import '../../../app/theme.dart';
import 'package:intl/intl.dart';
import '../../employee/data/employee_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  String fmt(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
  String fmtDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy').format(dt.toLocal());
  String fmtFull(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAuthService = ref.watch(employeeAuthServiceProvider);
    final currentEmployee = employeeAuthService.currentEmployee;

    if (currentEmployee == null) {
      return Container(
        color: AppTheme.kBackground,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.kNanoGold),
        ),
      );
    }

    final controller = attendanceControllerProvider(currentEmployee.id);
    final state = ref.watch(controller);

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
            _buildViewDetailsButton(context, state),
            const SizedBox(height: 20),
            // Recent Attendance List
            Expanded(child: _buildAttendanceList(state)),
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
                      currentEmployee.fullName,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: AsyncValueWidget<List<Attendance>>(
        value: state,
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
      child: AsyncValueWidget<List<Attendance>>(
        value: state,
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
              onPressed: () => ref.read(controller.notifier).toggleCheck(),
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
      ),
    );
  }

  Widget _buildViewDetailsButton(
    BuildContext context,
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

  Widget _buildAttendanceList(AsyncValue<List<Attendance>> state) {
    return Expanded(
      child: Container(
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
              child: AsyncValueWidget<List<Attendance>>(
                value: state,
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
              ),
            ),
          ],
        ),
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
      builder: (context) => Container(
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
              child: AsyncValueWidget<List<Attendance>>(
                value: state,
                data: (entries) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
