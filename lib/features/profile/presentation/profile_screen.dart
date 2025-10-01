import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../employee/data/employee_model.dart';
import '../../../core/utils/translation_helper.dart';

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

      // Debug: Check if employee ID exists
      print('🔍 Profile Debug: Employee ID: ${authService.currentEmployeeId}');
      print('🔍 Profile Debug: User ID: ${authService.currentUserId}');

      // Check if user is authenticated
      if (!authService.isAuthenticated ||
          authService.currentEmployeeId == null) {
        print('❌ User not authenticated or no employee ID');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await authService.getEmployeeProfile();

      // Debug: Print the response
      print('🔍 Profile Debug: API Response: $response');

      if (response['success'] == true) {
        final employeeData = response['employee'] as Map<String, dynamic>;
        setState(() {
          _employeeProfile = Employee.fromJson(employeeData);
          _isLoading = false;
        });
        print('✅ Profile loaded successfully');
      } else {
        print('❌ Profile loading failed: ${response['message']}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Profile loading error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
              ),
              const SizedBox(height: 16),
              Text(
                ref.t('กำลังโหลดโปรไฟล์...', 'Loading profile...'),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_employeeProfile == null) {
      final authService = ref.read(authServiceProvider);
      final isNotAuthenticated =
          !authService.isAuthenticated || authService.currentEmployeeId == null;

      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNotAuthenticated ? Icons.login : Icons.person_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isNotAuthenticated
                      ? ref.t('กรุณาเข้าสู่ระบบก่อน', 'Please Login First')
                      : ref.t(
                          'ไม่มีข้อมูลโปรไฟล์',
                          'No profile data available',
                        ),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isNotAuthenticated
                      ? ref.t(
                          'คุณต้องเข้าสู่ระบบเพื่อดูข้อมูลโปรไฟล์ของคุณ',
                          'You need to login to view your profile information.',
                        )
                      : ref.t(
                          'กรุณาตรวจสอบให้แน่ใจว่าคุณเข้าสู่ระบบแล้วและลองอีกครั้ง',
                          'Please make sure you are logged in and try again.',
                        ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (!isNotAuthenticated) ...[
                  ElevatedButton.icon(
                    onPressed: _loadEmployeeProfile,
                    icon: const Icon(Icons.refresh),
                    label: Text(ref.t('ลองใหม่', 'Retry')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kNanoGold,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to login using GoRouter
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: Text(
                    isNotAuthenticated
                        ? ref.t('เข้าสู่ระบบตอนนี้', 'Login Now')
                        : ref.t('ไปที่หน้าเข้าสู่ระบบ', 'Go to Login'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kNanoGold,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.kNanoGold,
        foregroundColor: Colors.white,
        title: Text(ref.t('โปรไฟล์', 'Profile')),
        actions: [
          IconButton(
            onPressed: _loadEmployeeProfile,
            icon: const Icon(Icons.refresh),
            tooltip: ref.t('รีเฟรชโปรไฟล์', 'Refresh Profile'),
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
            ref.t('ข้อมูลส่วนตัว', 'Personal Information'),
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
      ref.t('ชื่อเต็ม', 'Full Name'):
          '${employee.firstName} ${employee.lastName}',
      ref.t('รหัสพนักงาน', 'Employee ID'): employee.uid ?? '',
      ref.t('อีเมล', 'Email'): employee.email,
      ref.t('โทรศัพท์', 'Phone'): employee.primaryNumber ?? '-',
      ref.t('บริษัท', 'Company'): employee.companyName ?? '-',
      ref.t('สถานที่', 'Location'): employee.locationName ?? '-',
      ref.t('สาขา', 'Branch'): employee.branchName ?? '-',
      ref.t('ตำแหน่ง', 'Position'):
          employee.positionName ?? ref.t('พนักงาน', 'Employee'),

      ref.t('สถานะ', 'Status'): employee.status ?? ref.t('ใช้งาน', 'Active'),
      ref.t('วันเกิด', 'Date of Birth'): employee.dateOfBirth ?? '-',
      ref.t('เพศ', 'Gender'): employee.gender ?? '-',
      ref.t('สถานะสมรส', 'Marital Status'): employee.maritalStatus ?? '-',
      ref.t('วันที่เข้าร่วม', 'Join Date'): employee.joinDate != null
          ? DateTime.parse(
              employee.joinDate!,
            ).toLocal().toString().split(' ')[0]
          : ref.t('ไม่ระบุ', 'Not provided'),
      ref.t('เลขบัตรประชาชน', 'ID Card Number'):
          employee.idCardNumber ?? ref.t('ไม่ระบุ', 'Not provided'),
      ref.t('สัญชาติ', 'Nationality'):
          employee.nationality ?? ref.t('ไม่ระบุ', 'Not specified'),
      ref.t('คำนำหน้า', 'Title'):
          employee.title ?? ref.t('ไม่ระบุ', 'Not specified'),
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
    // Check for both Thai and English labels
    if (label.contains('ชื่อเต็ม') || label.contains('Full Name')) {
      return Icons.person;
    } else if (label.contains('รหัสพนักงาน') || label.contains('Employee ID')) {
      return Icons.badge;
    } else if (label.contains('อีเมล') || label.contains('Email')) {
      return Icons.email;
    } else if (label.contains('โทรศัพท์') || label.contains('Phone')) {
      return Icons.phone;
    } else if (label.contains('บริษัท') || label.contains('Company')) {
      return Icons.business;
    } else if (label.contains('สถานที่') || label.contains('Location')) {
      return Icons.location_on;
    } else if (label.contains('สาขา') || label.contains('Branch')) {
      return Icons.business_center;
    } else if (label.contains('ตำแหน่ง') || label.contains('Position')) {
      return Icons.work;
    } else if (label.contains('Role')) {
      return Icons.admin_panel_settings;
    } else if (label.contains('สถานะ') || label.contains('Status')) {
      return Icons.check_circle;
    } else if (label.contains('วันเกิด') || label.contains('Date of Birth')) {
      return Icons.cake;
    } else if (label.contains('เพศ') || label.contains('Gender')) {
      return Icons.person_outline;
    } else if (label.contains('สถานะสมรส') ||
        label.contains('Marital Status')) {
      return Icons.favorite;
    } else if (label.contains('วันที่เข้าร่วม') ||
        label.contains('Join Date')) {
      return Icons.calendar_today;
    } else if (label.contains('เลขบัตรประชาชน') ||
        label.contains('ID Card Number')) {
      return Icons.credit_card;
    } else if (label.contains('สัญชาติ') || label.contains('Nationality')) {
      return Icons.flag;
    } else if (label.contains('คำนำหน้า') || label.contains('Title')) {
      return Icons.title;
    } else {
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
