import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../app/theme.dart';
import '../../data/attendance_model.dart';

/// Modal for displaying attendance history
class AttendanceHistoryModal extends StatelessWidget {
  final Future<List<Attendance>> historyFuture;
  
  const AttendanceHistoryModal({
    super.key,
    required this.historyFuture,
  });
  
  @override
  Widget build(BuildContext context) {
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
          _buildHandle(),
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppTheme.kNanoGold,
            size: 24,
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          const Text(
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
    );
  }
  
  Widget _buildContent(BuildContext context) {
    return FutureBuilder<List<Attendance>>(
      future: historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(
            message: 'Loading attendance history...',
          );
        }
        
        if (snapshot.hasError) {
          return AppErrorWidget(
            message: 'Failed to load attendance history',
            onRetry: () {
              // Trigger rebuild by calling setState in parent
              Navigator.pop(context);
            },
          );
        }
        
        final entries = snapshot.data ?? [];
        
        if (entries.isEmpty) {
          return const EmptyStateWidget(
            message: 'No attendance records found',
            icon: Icons.access_time,
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildAttendanceCard(entry);
          },
        );
      },
    );
  }
  
  Widget _buildAttendanceCard(Attendance entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRow(entry),
            const SizedBox(height: AppConstants.smallPadding),
            if (entry.checkInAt != null) ...[
              _buildTimeRow(
                Icons.login,
                'Check In',
                AppDateUtils.formatTimeOnly(entry.checkInAt),
                AppTheme.kNanoGold,
              ),
              const SizedBox(height: AppConstants.smallPadding),
            ],
            if (entry.checkOutAt != null) ...[
              _buildTimeRow(
                Icons.logout,
                'Check Out',
                AppDateUtils.formatTimeOnly(entry.checkOutAt),
                Colors.green,
              ),
              const SizedBox(height: AppConstants.smallPadding),
            ],
            _buildLocationRow(entry.location),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateRow(Attendance entry) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today,
          color: AppTheme.kNanoGold,
          size: 20,
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Text(
          'Date: ${AppDateUtils.formatDateOnly(entry.checkInAt)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeRow(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppConstants.smallPadding),
        Text(
          '$label: $time',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  Widget _buildLocationRow(String location) {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          color: Colors.grey,
          size: 20,
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Text(
          'Location: $location',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
