import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final employeeId = authService.currentEmployeeId;

      if (employeeId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.t('ไม่พบข้อมูลผู้ใช้', 'User not found')),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      final apiService = ApiService();
      final result = await apiService.changePassword(
        employeeId: employeeId,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        confirmNewPassword: _confirmPasswordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
              title: Text(
                ref.t('สำเร็จ', 'Success'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kOnSurface,
                ),
              ),
              content: Text(
                result['message'] ??
                    ref.t(
                      'เปลี่ยนรหัสผ่านสำเร็จ',
                      'Password changed successfully',
                    ),
                style: TextStyle(color: AppTheme.kOnSurface),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    Navigator.of(context).pop(); 
                  },
                  child: Text(
                    ref.t('ตกลง', 'OK'),
                    style: TextStyle(color: AppTheme.kNanoGold),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    ref.t(
                      'เปลี่ยนรหัสผ่านล้มเหลว',
                      'Failed to change password',
                    ),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.t(
                'เกิดข้อผิดพลาด: ${e.toString()}',
                'An error occurred: ${e.toString()}',
              ),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          ref.t('เปลี่ยนรหัสผ่าน', 'Change Password'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: ref.t('รหัสผ่านปัจจุบัน', 'Current Password'),
                  hintText: ref.t('กรอกรหัสผ่านปัจจุบัน', 'Enter current password'),
                  prefixIcon: Icon(Icons.lock, color: AppTheme.kNanoGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.kOnSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.t(
                      'กรุณากรอกรหัสผ่านปัจจุบัน',
                      'Please enter current password',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: ref.t('รหัสผ่านใหม่', 'New Password'),
                  hintText: ref.t('กรอกรหัสผ่านใหม่', 'Enter new password'),
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.kNanoGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.kOnSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.t(
                      'กรุณากรอกรหัสผ่านใหม่',
                      'Please enter new password',
                    );
                  }
                  if (value.length < 6) {
                    return ref.t(
                      'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
                      'Password must be at least 6 characters',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: ref.t('ยืนยันรหัสผ่านใหม่', 'Confirm New Password'),
                  hintText: ref.t(
                    'กรอกรหัสผ่านใหม่อีกครั้ง',
                    'Re-enter new password',
                  ),
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.kNanoGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.kOnSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.kNanoGold,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.t(
                      'กรุณายืนยันรหัสผ่านใหม่',
                      'Please confirm new password',
                    );
                  }
                  if (value != _newPasswordController.text) {
                    return ref.t(
                      'รหัสผ่านไม่ตรงกัน',
                      'Passwords do not match',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
                
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kNanoGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          ref.t('เปลี่ยนรหัสผ่าน', 'Change Password'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

