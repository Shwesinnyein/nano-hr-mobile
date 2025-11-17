import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../employee/presentation/employee_list_screen.dart';
import '../../attendance/presentation/employee_attendance_history_screen.dart';
import '../../attendance/presentation/attendance_history_screen.dart';
import '../../auth/data/auth_repository.dart' as auth;
import 'change_password_screen.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Check if user is HR or approver
  bool _isHROrApprover(AuthService auth) {
    final position = auth.currentPositionName ?? '';
    final positionLower = position.toLowerCase();
    
    // Check if user is HR
    if (positionLower.contains('hr') ||
        positionLower.contains('human resource')) {
      return true;
    }
    
    // Check if user is an approver
    if (positionLower.contains('approver') ||
        positionLower.contains('management')) {
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final isHROrApprover = _isHROrApprover(authService);
    
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          ref.t('การตั้งค่า', 'Settings'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsSection(ref.t('องค์กร', 'Organization'), [
              // _buildSettingsItem(
              //   ref.t('ข้อมูลบริษัท', 'Company Information'),
              //   ref.t(
              //     'ดูรายละเอียดบริษัทและนโยบาย',
              //     'View company details and policies',
              //   ),
              //   Icons.business,
              //   () => _showComingSoon(
              //     context,
              //     ref.t('ข้อมูลบริษัท', 'Company Information'),
              //   ),
              // ),
              // _buildSettingsItem(
              //   ref.t('โครงสร้างแผนก', 'Department Structure'),
              //   ref.t('ดูลำดับชั้นองค์กร', 'View organizational hierarchy'),
              //   Icons.account_tree,
              //   () => _showComingSoon(
              //     context,
              //     ref.t('โครงสร้างแผนก', 'Department Structure'),
              //   ),
              // ),
              // _buildSettingsItem(
              //   ref.t('ไดเรกทอรีพนักงาน', 'Employee Directory'),
              //   ref.t('เรียกดูรายชื่อพนักงาน', 'Browse employee contacts'),
              //   Icons.contacts,
              //   () => _showComingSoon(
              //     context,
              //     ref.t('ไดเรกทอรีพนักงาน', 'Employee Directory'),
              //   ),
              // ),
              _buildSettingsItem(
                ref.t('รายชื่อพนักงาน', 'Employee List'),
                ref.t(
                  'ดูพนักงานทั้งหมดและรายละเอียด',
                  'View all employees and their details',
                ),
                Icons.people,
                () => _navigateToEmployeeList(context),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(ref.t('การเข้างาน', 'Attendance'), [
              _buildSettingsItem(
                ref.t('ประวัติการเข้างาน', 'Attendance History'),
                ref.t(
                  'ดูประวัติการเข้างานของคุณ',
                  'View your attendance records',
                ),
                Icons.history,
                () => _navigateToAttendanceHistory(context),
              ),
              // Only show "Attendance History by Employee" for HR and approvers
              if (isHROrApprover)
                _buildSettingsItem(
                  ref.t(
                    'ประวัติการเข้างานของพนักงาน',
                    'Attendance History by Employee',
                  ),
                  ref.t(
                    'ดูประวัติการเข้างานของพนักงานทั้งหมด',
                    'View attendance records for all employees',
                  ),
                  Icons.people_alt,
                  () => _navigateToEmployeeAttendanceHistory(context),
                ),
              // _buildSettingsItem(
              //   ref.t('ติดตามเวลา', 'Time Tracking'),
              //   ref.t('เช็คอิน/เช็คเอาท์และเวลาพัก', 'Check in/out and break times'),
              //   Icons.access_time,
              //   () => _showComingSoon(context, ref.t('ติดตามเวลา', 'Time Tracking')),
              // ),
              // _buildSettingsItem(
              //   ref.t('รายงานการเข้างาน', 'Attendance Reports'),
              //   ref.t('สร้างรายงานการเข้างาน', 'Generate attendance reports'),
              //   Icons.assessment,
              //   () => _showComingSoon(
              //     context,
              //     ref.t('รายงานการเข้างาน', 'Attendance Reports'),
              //   ),
              // ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(ref.t('การเงิน', 'Financial'), [
              _buildSettingsItem(
                ref.t('เงินเดือน', 'Payroll'),
                ref.t(
                  'ดูเงินเดือนและใบรับเงินเดือน',
                  'View salary and payslips',
                ),
                Icons.account_balance_wallet,
                () => _showComingSoon(context, ref.t('เงินเดือน', 'Payroll')),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(ref.t('การสนับสนุน', 'Support'), [
              _buildSettingsItem(
                ref.t('รายงานปัญหา', 'Problem Report'),
                ref.t('รายงานปัญหาและข้อผิดพลาด', 'Report issues and problems'),
                Icons.report_problem,
                () => _showComingSoon(
                  context,
                  ref.t('รายงานปัญหา', 'Problem Report'),
                ),
              ),

              _buildSettingsItem(
                ref.t('ติดต่อ IT', 'Contact IT'),
                ref.t('ติดต่อฝ่ายสนับสนุน IT', 'Contact IT support'),
                Icons.support_agent,
                () =>
                    _showComingSoon(context, ref.t('ติดต่อ IT', 'Contact IT')),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(ref.t('บัญชี', 'Account'), [
              _buildSettingsItem(
                ref.t('เปลี่ยนรหัสผ่าน', 'Change Password'),
                ref.t(
                  'เปลี่ยนรหัสผ่านของคุณ',
                  'Change your password',
                ),
                Icons.lock,
                () => _navigateToChangePassword(context),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(ref.t('การตั้งค่าแอป', 'App Settings'), [
              _buildLanguageSelector(context, ref),
              _buildNotificationToggle(context, ref),
              _buildSettingsItem(
                ref.t('การตั้งค่าความเป็นส่วนตัว', 'Privacy Settings'),
                ref.t(
                  'จัดการความเป็นส่วนตัวและความปลอดภัย',
                  'Manage privacy and security',
                ),
                Icons.privacy_tip,
                () => _openPrivacyPolicy(context),
              ),
              _buildLogoutButton(context, ref),
              _buildVersionInfo(ref),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.kNanoGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.kNanoGold, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSegmentedControl(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(languageProvider);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(context, ref, 'TH', 'ไทย', isThai),
          _buildLanguageOption(context, ref, 'ENG', 'EN', !isThai),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String code,
    String text,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        // Update global language state
        ref.read(languageProvider.notifier).setLanguage(code == 'TH');
        _showLanguageChanged(context, code);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.kNanoGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language,
                  color: AppTheme.kNanoGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.t('ภาษา', 'Language'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ref.t(
                        'เลือกภาษาที่คุณต้องการ',
                        'Choose your preferred language',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _buildLanguageSegmentedControl(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppTheme.kNanoGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.t('การแจ้งเตือน', 'Notifications'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ref.t(
                        'เปิดหรือปิดการแจ้งเตือนของแอป',
                        'Enable or disable app notifications',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (bool value) {
                  _showNotificationToggle(context, ref, value);
                },
                activeThumbColor: AppTheme.kNanoGold,
                activeTrackColor: AppTheme.kNanoGold.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLogoutDialog(context, ref),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.t('ออกจากระบบ', 'Logout'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ref.t('ออกจากบัญชีของคุณ', 'Sign out of your account'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.kNanoGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info, color: AppTheme.kNanoGold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.t('เวอร์ชัน', 'Version'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nano HR Mobile v1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.kNanoGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageChanged(BuildContext context, String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language changed to ${language == 'ENG' ? 'English' : 'ไทย'}',
        ),
        backgroundColor: AppTheme.kNanoGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationToggle(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.t(
            'การแจ้งเตือน${isEnabled ? 'เปิดใช้งาน' : 'ปิดใช้งาน'}',
            'Notifications ${isEnabled ? 'enabled' : 'disabled'}',
          ),
        ),
        backgroundColor: AppTheme.kNanoGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            ref.t('ออกจากระบบ', 'Logout'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            ref.t(
              'คุณแน่ใจหรือไม่ที่จะออกจากระบบ?',
              'Are you sure you want to logout?',
            ),
            style: const TextStyle(fontSize: 16),
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
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                ref.t('ออกจากระบบ', 'Logout'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      // Use the AuthController to properly handle logout and navigation
      await ref.read(auth.authStateProvider.notifier).logout();

      if (context.mounted) {
        // Navigate to login page using GoRouter
        context.go('/login');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.t('ออกจากระบบสำเร็จ', 'Logged out successfully')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.t(
                'ออกจากระบบล้มเหลว: ${e.toString()}',
                'Logout failed: ${e.toString()}',
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToEmployeeList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
    );
  }

  void _navigateToEmployeeAttendanceHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeAttendanceHistoryScreen(),
      ),
    );
  }

  void _navigateToAttendanceHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppTheme.kNanoGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      final url = Uri.parse(AppConstants.privacyPolicyUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
