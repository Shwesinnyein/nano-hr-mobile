import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/otp_provider.dart';
import '../../../core/utils/translation_helper.dart';

enum ForgotPasswordStep { email, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _emailOrEmployeeId;
  String? _otp;

  @override
  void initState() {
    super.initState();
    // Listen for OTP from notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForOTP();
    });
  }

  void _listenForOTP() {
    // Listen to OTP provider and auto-fill when OTP is received
    ref.listen<String?>(otpProvider, (previous, next) {
      if (next != null && 
          _currentStep == ForgotPasswordStep.otp && 
          _otpController.text.isEmpty) {
        setState(() {
          _otpController.text = next;
        });
        // Clear OTP after using it
        ref.read(otpProvider.notifier).clearOTP();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Translation helper
  String _t(String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  Future<void> _requestOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('กรุณากรอกอีเมล', 'Please enter your email'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('กรุณากรอกอีเมลที่ถูกต้อง', 'Please enter a valid email'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.forgotPassword(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          setState(() {
            _emailOrEmployeeId = email;
            _currentStep = ForgotPasswordStep.otp;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    _t(
                      'เราได้ส่ง OTP ไปยังอุปกรณ์ของคุณแล้ว',
                      'OTP has been sent to your device',
                    ),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    _t('เกิดข้อผิดพลาด', 'An error occurred'),
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
              _t(
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

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('กรุณากรอก OTP 6 หลัก', 'Please enter 6-digit OTP'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.verifyResetOTP(
        email: _emailOrEmployeeId!,
        otp: otp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          setState(() {
            _otp = otp;
            _currentStep = ForgotPasswordStep.newPassword;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    _t('OTP ไม่ถูกต้อง', 'Invalid OTP'),
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
              _t(
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

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('กรุณากรอกรหัสผ่าน', 'Please enter password'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร', 'Password must be at least 6 characters'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('รหัสผ่านไม่ตรงกัน', 'Passwords do not match'),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.resetPassword(
        email: _emailOrEmployeeId!,
        otp: _otp!,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
              title: Text(
                _t('สำเร็จ', 'Success'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kOnSurface,
                ),
              ),
              content: Text(
                result['message'] ??
                    _t(
                      'เปลี่ยนรหัสผ่านสำเร็จ',
                      'Password reset successfully',
                    ),
                style: TextStyle(color: AppTheme.kOnSurface),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login
                  },
                  child: Text(
                    _t('ตกลง', 'OK'),
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
                    _t('เกิดข้อผิดพลาด', 'An error occurred'),
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
              _t(
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
          _t('ลืมรหัสผ่าน', 'Forgot Password'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Row(
              children: [
                _buildStepIndicator(
                  1,
                  _t('อีเมล', 'Email'),
                  _currentStep == ForgotPasswordStep.email,
                  _currentStep.index > 0,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep.index > 0
                        ? AppTheme.kNanoGold
                        : Colors.grey[300],
                  ),
                ),
                _buildStepIndicator(
                  2,
                  _t('OTP', 'OTP'),
                  _currentStep == ForgotPasswordStep.otp,
                  _currentStep.index > 1,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep.index > 1
                        ? AppTheme.kNanoGold
                        : Colors.grey[300],
                  ),
                ),
                _buildStepIndicator(
                  3,
                  _t('รหัสผ่านใหม่', 'New Password'),
                  _currentStep == ForgotPasswordStep.newPassword,
                  false,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Step content
            if (_currentStep == ForgotPasswordStep.email) _buildEmailStep(),
            if (_currentStep == ForgotPasswordStep.otp) _buildOTPStep(),
            if (_currentStep == ForgotPasswordStep.newPassword)
              _buildNewPasswordStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? AppTheme.kNanoGold
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive || isCompleted
                ? AppTheme.kNanoGold
                : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('กรุณากรอกอีเมลของคุณ', 'Please enter your email'),
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.kOnSurface,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t('อีเมล', 'Email'),
            hintText: _t('กรอกอีเมล', 'Enter your email'),
            prefixIcon: Icon(Icons.email, color: AppTheme.kNanoGold),
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
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kNanoGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _t('ส่ง OTP', 'Send OTP'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t(
            'กรุณากรอก OTP ที่ได้รับจากอุปกรณ์ของคุณ',
            'Please enter the OTP received on your device',
          ),
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.kOnSurface,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: _t('OTP (6 หลัก)', 'OTP (6 digits)'),
            hintText: _t('กรอก OTP', 'Enter OTP'),
            prefixIcon: Icon(Icons.lock, color: AppTheme.kNanoGold),
            counterText: '',
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
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _currentStep = ForgotPasswordStep.email;
                          _otpController.clear();
                        });
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.kNanoGold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _t('ย้อนกลับ', 'Back'),
                  style: TextStyle(color: AppTheme.kNanoGold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kNanoGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                        _t('ยืนยัน OTP', 'Verify OTP'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('กรุณากรอกรหัสผ่านใหม่', 'Please enter your new password'),
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.kOnSurface,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: _t('รหัสผ่านใหม่', 'New Password'),
            hintText: _t('กรอกรหัสผ่านใหม่', 'Enter new password'),
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.kNanoGold),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
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
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: _t('ยืนยันรหัสผ่านใหม่', 'Confirm New Password'),
            hintText: _t('กรอกรหัสผ่านใหม่อีกครั้ง', 'Re-enter new password'),
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
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _currentStep = ForgotPasswordStep.otp;
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.kNanoGold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _t('ย้อนกลับ', 'Back'),
                  style: TextStyle(color: AppTheme.kNanoGold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kNanoGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                        _t('เปลี่ยนรหัสผ่าน', 'Reset Password'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

