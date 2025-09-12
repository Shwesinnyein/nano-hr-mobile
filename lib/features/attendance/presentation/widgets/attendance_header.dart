import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/app_theme_refactored.dart';

/// Header widget for attendance screen
class AttendanceHeader extends StatelessWidget {
  final Map<String, dynamic>? employeeProfile;
  final Map<String, dynamic>? attendanceStatus;
  final bool isLoading;

  const AttendanceHeader({
    super.key,
    this.employeeProfile,
    this.attendanceStatus,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeRefactored.kNanoGold,
            AppThemeRefactored.kNanoGoldDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeRefactored.kNanoGold.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildWelcomeSection(),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildStatusSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    if (isLoading) {
      return const Row(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(width: AppConstants.defaultPadding),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final employeeName =
        employeeProfile?['firstName'] != null &&
            employeeProfile?['lastName'] != null
        ? '${employeeProfile!['firstName']} ${employeeProfile!['lastName']}'
        : employeeProfile?['nickname'] ?? 'Employee';

    final companyName = employeeProfile?['companyName'] ?? 'NANO-STORES';
    final locationName = employeeProfile?['locationName'] ?? 'Bangkok';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          employeeName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.business,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              companyName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.location_on,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              locationName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(width: AppConstants.defaultPadding),
            Text('Loading status...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final status = attendanceStatus?['status'] ?? 'not_checked_in';
    final checkInTime = attendanceStatus?['record']?['checkInAt'];
    final checkOutTime = attendanceStatus?['record']?['checkOutAt'];

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'checked_in':
        statusText = AppConstants.checkedInMessage;
        statusColor = Colors.green;
        statusIcon = Icons.login;
        break;
      case 'checked_out':
        statusText = AppConstants.checkedOutMessage;
        statusColor = Colors.blue;
        statusIcon = Icons.logout;
        break;
      default:
        statusText = AppConstants.notCheckedInMessage;
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Status: $statusText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (checkInTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Check In: ${AppDateUtils.formatTimeOnly(AppDateUtils.parseTimeWithDate(checkInTime, AppDateUtils.getToday().toIso8601String().split('T')[0]))}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
          if (checkOutTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Check Out: ${AppDateUtils.formatTimeOnly(AppDateUtils.parseTimeWithDate(checkOutTime, AppDateUtils.getToday().toIso8601String().split('T')[0]))}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
