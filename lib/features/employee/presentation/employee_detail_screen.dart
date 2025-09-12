import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../data/employee_repository.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          employee.name,
          style: const TextStyle(
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
            icon: Icon(Icons.more_vert, color: AppTheme.kOnBackground),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildEmployeeInfo(context),
            _buildContactInfo(context),
            _buildWorkInfo(context),
            _buildAdditionalInfo(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 16),
          Text(
            '${employee.firstName ?? ''} ${employee.lastName ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.kNanoWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            employee.positionName ?? 'Employee',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.kNanoWhite.withOpacity(0.8),
            ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   employee.positionName ?? '',
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: AppTheme.kNanoWhite.withOpacity(0.7),
          //   ),
          // ),
          // const SizedBox(height: 16),
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    // Check if employee has a profile image URL
    if (employee.profileImage != null && employee.profileImage!.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.kNanoWhite.withOpacity(0.3),
            width: 3,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            employee.profileImage!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to initials if image fails to load
              return _buildInitialsAvatar();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingAvatar();
            },
          ),
        ),
      );
    }

    // Fallback to initials if no profile image
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.kNanoWhite.withOpacity(0.2),
        border: Border.all(
          color: AppTheme.kNanoWhite.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: AppTheme.kNanoWhite,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.kNanoWhite.withOpacity(0.2),
        border: Border.all(
          color: AppTheme.kNanoWhite.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoWhite),
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    String initials = '';

    // Try to get initials from firstName and lastName
    if (employee.firstName != null && employee.firstName!.isNotEmpty) {
      initials += employee.firstName![0].toUpperCase();
    }
    if (employee.lastName != null && employee.lastName!.isNotEmpty) {
      initials += employee.lastName![0].toUpperCase();
    }

    // Fallback to name field
    if (initials.isEmpty && employee.name.isNotEmpty) {
      initials = employee.name[0].toUpperCase();
    }

    // Final fallback
    if (initials.isEmpty) {
      initials = '?';
    }

    return initials;
  }

  Widget _buildStatusChip() {
    Color statusColor = employee.status == 'active'
        ? Colors.green
        : employee.status == 'inactive'
        ? Colors.orange
        : Colors.red;
    String statusText = employee.status == 'active'
        ? 'Active'
        : employee.status == 'inactive'
        ? 'Inactive'
        : 'Resigned';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo(BuildContext context) {
    return _buildInfoSection('Employee Information', Icons.person, [
      _buildInfoItem(context, 'Employee ID', employee.id),
      _buildInfoItem(
        context,
        'Birthday',
        _formatDate(
          employee.dateOfBirth is DateTime
              ? employee.dateOfBirth as DateTime
              : DateTime.now(),
        ),
      ),
      if (employee.managerName != null)
        _buildInfoItem(context, 'Manager', employee.managerName!),
    ]);
  }

  Widget _buildContactInfo(BuildContext context) {
    return _buildInfoSection('Contact Information', Icons.contact_phone, [
      if (employee.email != null)
        _buildInfoItem(context, 'Email', employee.email!, isEmail: true),
      _buildInfoItem(
        context,
        'Phone',
        employee.primary_number ?? '',
        isPhone: true,
      ),
      // _buildInfoItem(context, 'Line ID', employee.lineId ?? ''),
      if (employee.additionalInfo?['location'] != null)
        _buildInfoItem(
          context,
          'Location',
          employee.additionalInfo!['location'],
        ),
    ]);
  }

  Widget _buildWorkInfo(BuildContext context) {
    return _buildInfoSection('Work Information', Icons.work, [
      if (employee.position != null)
        _buildInfoItem(context, 'Position', employee.positionName!),
      _buildInfoItem(context, 'Company', employee.companyName),
      _buildInfoItem(context, 'Location', employee.locationName),
      _buildInfoItem(context, 'Branch', employee.branchName ?? ''),
      _buildInfoItem(
        context,
        'Join Date',
        _formatDate(employee.joinDate ?? DateTime.now()),
      ),
    ]);
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    if (employee.additionalInfo == null || employee.additionalInfo!.isEmpty) {
      return const SizedBox.shrink();
    }

    final additionalItems = <Widget>[];

    if (employee.additionalInfo?['birthday'] != null) {
      additionalItems.add(
        _buildInfoItem(
          context,
          'Birthday',
          employee.additionalInfo!['birthday'],
        ),
      );
    }

    if (additionalItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildInfoSection(
      'Additional Information',
      Icons.info,
      additionalItems,
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.kNanoGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kOnBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.kOnSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isEmail
                  ? () => _launchEmail(context, value)
                  : isPhone
                  ? () => _launchPhone(context, value)
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isEmail || isPhone
                      ? AppTheme.kNanoGold
                      : AppTheme.kOnSurface,
                  fontWeight: FontWeight.w500,
                  decoration: isEmail || isPhone
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _launchEmail(BuildContext context, String email) {
    // In a real app, you would launch the email client
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email: $email'),
        backgroundColor: AppTheme.kNanoGold,
      ),
    );
  }

  void _launchPhone(BuildContext context, String phone) {
    // In a real app, you would launch the phone dialer
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling: $phone'),
        backgroundColor: AppTheme.kNanoGold,
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.message, color: AppTheme.kNanoGold),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                if (employee.email != null) {
                  _launchEmail(context, employee.email!);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.kNanoGold),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _launchPhone(context, employee.primary_number ?? '');
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: AppTheme.kNanoGold),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
