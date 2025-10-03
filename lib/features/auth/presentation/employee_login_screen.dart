import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/language_provider.dart';

class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  ConsumerState<EmployeeLoginScreen> createState() =>
      _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showRegistration = false;
  bool _isLoading = false;

  // Translation helper method using global state
  String _t(WidgetRef ref, String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_showRegistration) {
      // Registration flow
      if (_password.text != _confirmPassword.text) {
        _showErrorSnackBar('Passwords do not match');
        return;
      }
      _performRegistration(_email.text, _password.text, _confirmPassword.text);
    } else {
      // Login flow
      _performLogin(_email.text, _password.text);
    }
  }

  void _performRegistration(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final authService = ref.read(authServiceProvider);

      // Show loading
      _showLoadingSnackBar('Verifying employee email...');

      // Check if email exists in employee system
      final emailCheckResult = await authService.checkEmailExists(email);

      // Debug: Print the response to see what we're getting
      print('🔍 Email check result: $emailCheckResult');

      // If API call failed, show error
      if (emailCheckResult['success'] == false) {
        _showErrorSnackBar('Failed to verify email. Please try again.');
        return;
      }

      // If email doesn't exist in system, show error
      if (emailCheckResult['exists'] == false) {
        _showErrorSnackBar(
          'Email not found in system. Please contact HR to add your email to the employee database.',
        );
        return;
      }

      // If exists is null or undefined, assume it doesn't exist for safety
      if (emailCheckResult['exists'] == null) {
        _showErrorSnackBar(
          'Email verification failed. Please contact HR to verify your email.',
        );
        return;
      }
      final result = await authService.registerUser(
        email,
        password,
        confirmPassword,
      );

      if (result['success'] == true) {
        // Update auth state directly
        ref
            .read(authServiceProvider)
            .setCurrentUser('user-${DateTime.now().millisecondsSinceEpoch}');

        // Success - show message first, then navigate
        if (mounted) {
          _showSuccessSnackBar('Registration successful! Welcome to NANO HR!');
          _showRegistration = false;
          // await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            context.go('/employee-login');
          }
          // Add delay to ensure user sees the success message before navigation
          // await Future.delayed(const Duration(milliseconds: 1500));
          // if (mounted) {
          //   context.go('/attendance');
          // }
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        // Show API error message directly
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _performLogin(String email, String password) async {
    try {
      final authService = ref.read(authServiceProvider);

      // Show loading
      _showLoadingSnackBar('Authenticating...');

      // Login using API
      final result = await authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (result['success'] == true) {
        // The auth service already sets the user ID and employee ID correctly
        // No need to override it with a dummy ID

        // Success - show message first, then navigate
        if (mounted) {
          _showSuccessSnackBar('Login successful!');
          // Add delay to ensure user sees the success message before navigation
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            context.go('/attendance');
          }
        }
      } else {
        // Show API error message directly
        _showErrorSnackBar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        // Show API error message directly
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.kNanoGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFc7a27b), // Your specified color
              const Color(0xFFb8956b), // Slightly darker shade
              const Color(0xFFa0855a), // Even darker for depth
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language Switch in top right
              Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildLanguageSwitch()],
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // Modern Logo Section
                      _buildModernLogo(),

                      const SizedBox(height: 20),

                      // Modern Card Container
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              // Modern Mode Indicator
                              _buildModernModeIndicator(),

                              const SizedBox(height: 20),

                              // Modern Form Fields
                              _buildModernTextField(
                                controller: _email,
                                label: _t(
                                  ref,
                                  'อีเมลพนักงาน',
                                  'Employee Email',
                                ),
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 16),

                              _buildModernTextField(
                                controller: _password,
                                label: _t(ref, 'รหัสผ่าน', 'Password'),
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),

                              // Confirm Password field (only show in registration mode)
                              if (_showRegistration) ...[
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller: _confirmPassword,
                                  label: _t(
                                    ref,
                                    'ยืนยันรหัสผ่าน',
                                    'Confirm Password',
                                  ),
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Modern 3D Button
                              _buildModern3DButton(),

                              const SizedBox(height: 24),

                              // Modern Toggle Button
                              _buildModernToggleButton(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Logo Section
  Widget _buildModernLogo() {
    return Column(
      children: [
        // 3D Logo Container
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFf8f9fa)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/icon/nano-store-dark.png',
              height: 80,
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.business_rounded,
                  size: 60,
                  color: Color(0xFFc7a27b),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Modern App Name
        Text(
          _t(ref, 'NANO Work', 'NANO Work'),
          style: TextStyle(
            fontSize: 28, // Reduced from 32
            fontWeight: FontWeight.w700, // Reduced from w800
            color: Colors.white,
            letterSpacing: 1.5, // Reduced from 2
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        // const SizedBox(height: 8),
        // Text(
        //   'Employee Portal',
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w400,
        //     color: Colors.white.withOpacity(0.9),
        //     letterSpacing: 1,
        //   ),
        // ),
      ],
    );
  }

  // Modern Mode Indicator
  Widget _buildModernModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFc7a27b).withOpacity(0.1),
            const Color(0xFFb8956b).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFc7a27b).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _showRegistration ? Icons.person_add_rounded : Icons.login_rounded,
            color: const Color(0xFFc7a27b),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _showRegistration
                  ? _t(ref, 'พนักงานใหม่', 'New Employee')
                  : _t(ref, 'เข้าสู่ระบบพนักงาน', 'Employee Login'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFc7a27b),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 50, // Reduced height
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12), // Smaller radius
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 15, // Slightly smaller font
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13, // Smaller label
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8), // Reduced margin
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFFc7a27b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // Smaller radius
            ),
            child: Icon(
              icon,
              color: const Color(0xFFc7a27b),
              size: 18,
            ), // Smaller icon
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFc7a27b), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, // Reduced horizontal padding
            vertical: 12, // Reduced vertical padding
          ),
        ),
      ),
    );
  }

  // Modern 3D Button
  Widget _buildModern3DButton() {
    return Container(
      width: double.infinity,
      height: 52, // Increased from 48 for better text visibility
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFc7a27b), Color(0xFFb8956b)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFc7a27b).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showRegistration ? _handleRegistration : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showRegistration
                        ? Icons.person_add_rounded
                        : Icons.login_rounded,
                    color: Colors.white,
                    size: 18, // Reduced from 20
                  ),
                  const SizedBox(width: 6), // Reduced from 8
                  Text(
                    _showRegistration
                        ? _t(ref, 'สร้างบัญชี', 'Create Account')
                        : _t(ref, 'เข้าสู่ระบบ', 'Sign In'),
                    style: const TextStyle(
                      fontSize: 15, // Increased from 14
                      fontWeight: FontWeight.w700, // Increased from w600
                      color: Colors.white,
                      letterSpacing: 0.5, // Increased from 0.3
                      shadows: const [
                        Shadow(
                          color: Color(
                            0x4D000000,
                          ), // Colors.black.withOpacity(0.3)
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Modern Toggle Button
  Widget _buildModernToggleButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            setState(() {
              _showRegistration = !_showRegistration;
              _password.clear();
              _confirmPassword.clear();
            });
          },
          child: Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                children: [
                  TextSpan(
                    text: _showRegistration
                        ? _t(ref, 'มีบัญชีแล้ว? ', 'Already have an account? ')
                        : _t(ref, 'ไม่มีบัญชี? ', 'Don\'t have an account? '),
                  ),
                  TextSpan(
                    text: _showRegistration
                        ? _t(ref, 'เข้าสู่ระบบ', 'Sign In')
                        : _t(ref, 'สมัครสมาชิก', 'Sign Up'),
                    style: const TextStyle(
                      color: Color(0xFFc7a27b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handle Registration
  Future<void> _handleRegistration() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    // Call the actual registration method with email validation
    _performRegistration(_email.text, _password.text, _confirmPassword.text);
  }

  // Language Switch Widget
  Widget _buildLanguageSwitch() {
    final isThai = ref.watch(languageProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              ref.read(languageProvider.notifier).setLanguage(true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isThai
                    ? Colors.white.withOpacity(0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'TH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isThai ? const Color(0xFFc7a27b) : Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(languageProvider.notifier).setLanguage(false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !isThai
                    ? Colors.white.withOpacity(0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'EN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !isThai ? const Color(0xFFc7a27b) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
