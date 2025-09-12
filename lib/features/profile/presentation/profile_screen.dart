import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../employee/data/employee_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _profileImage;
  Employee? _employeeProfile;
  bool _isLoading = true;

  // final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEmployeeProfile();
  }

  Future<void> _loadEmployeeProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = ref.read(authServiceProvider);
      final response = await authService.getEmployeeProfile();

      if (response['success'] == true) {
        final employeeData = response['employee'] as Map<String, dynamic>;
        setState(() {
          _employeeProfile = Employee.fromJson(employeeData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_employeeProfile == null) {
      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No profile data available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEmployeeProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kNanoGold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.kNanoGold,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _loadEmployeeProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(_employeeProfile!),
            const SizedBox(height: 24),
            _buildPersonalInformation(_employeeProfile!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Employee employee) {
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
          const SizedBox(height: 20),
          _buildProfilePhoto(employee),
          const SizedBox(height: 16),
          Text(
            employee.fullName,
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
          const SizedBox(height: 8),
          Text(
            employee.companyName ?? 'NANO-STORES',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.kNanoWhite.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(Employee employee) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.kNanoWhite, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: _profileImage != null
              ? Image.file(_profileImage!, fit: BoxFit.cover)
              : employee.profileImage != null
              ? Image.network(
                  employee.profileImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.kNanoWhite.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.kNanoWhite,
                      ),
                    );
                  },
                )
              : Container(
                  color: AppTheme.kNanoWhite.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppTheme.kNanoWhite,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPersonalInformation(Employee employee) {
    final personalInfo = _getPersonalInfoMap(employee);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.kOnBackground,
            ),
          ),
          const SizedBox(height: 16),
          ...personalInfo.entries.map(
            (entry) => _buildInfoCard(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getPersonalInfoMap(Employee employee) {
    return {
      'Full Name': employee.firstName + ' ' + employee.lastName,
      'Employee ID': employee.uid ?? '',
      'Email': employee.email,
      'Phone': employee.primaryNumber ?? '-',
      'Company': employee.companyName ?? '-',
      'Location': employee.locationName ?? '-',
      'Branch': employee.branchName ?? '-',
      'Position': employee.positionName ?? 'Employee',

      'Status': employee.status ?? 'Active',
      'Date of Birth': employee.dateOfBirth ?? '-',
      'Gender': employee.gender ?? '-',
      'Marital Status': employee.maritalStatus ?? '-',
      'Join Date': employee.joinDate != null
          ? DateTime.parse(
              employee.joinDate!,
            ).toLocal().toString().split(' ')[0]
          : 'Not provided',
      'ID Card Number': employee.idCardNumber ?? 'Not provided',
      'Nationality': employee.nationality ?? 'Not specified',
      'Title': employee.title ?? 'Not specified',
    };
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.kNanoGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getInfoIcon(label),
              color: AppTheme.kNanoGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.kOnSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.kOnSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInfoIcon(String label) {
    switch (label) {
      case 'Full Name':
        return Icons.person;
      case 'Employee ID':
        return Icons.badge;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      case 'Company':
        return Icons.business;
      case 'Location':
        return Icons.location_on;
      case 'Branch':
        return Icons.business_center;
      case 'Position':
        return Icons.work;
      case 'Role':
        return Icons.admin_panel_settings;
      case 'Status':
        return Icons.check_circle;
      case 'Date of Birth':
        return Icons.cake;
      case 'Gender':
        return Icons.person_outline;
      case 'Marital Status':
        return Icons.favorite;
      case 'Join Date':
        return Icons.calendar_today;
      case 'ID Card Number':
        return Icons.credit_card;
      case 'Nationality':
        return Icons.flag;
      case 'Title':
        return Icons.title;
      default:
        return Icons.info;
    }
  }

  void _pickProfileImage() async {
    // final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _profileImage = File(image.path);
    //   });
    // }
    // TODO: Implement image picking when image_picker is re-enabled
  }
}
