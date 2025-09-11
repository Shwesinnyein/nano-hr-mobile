import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/employee_auth_service.dart';
import '../data/auth_repository.dart';
import '../../employee/data/employee_model.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Just navigate to attendance - no validation needed
    print('🔄 Login button clicked');

    // Set mock employee data
    final employeeAuthService = ref.read(employeeAuthServiceProvider);
    employeeAuthService.setCurrentEmployee(
      Employee.fromJson({
        'id': 'emp001',
        'uid': 'emp001',
        'fullName': 'John Doe',
        'email': 'john.doe@company.com',
        'position': 'Software Developer',
        'department': 'IT',
        'branch': 'office',
        'phoneNumber': '+1234567890',
        'hireDate': '2023-01-15',
        'status': 'active',
        'profileImageUrl': null,
      }),
    );

    ref.read(authStateProvider.notifier).setLoggedIn(true);
    print('✅ Auth state set to logged in');
    context.go('/attendance');
    print('🔄 Navigating to attendance');
  }

  void _performRegistration(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final authService = ref.read(employeeAuthServiceProvider);

      // Show loading
      _showLoadingSnackBar('Setting up your account...');

      // Register and login
      await authService.registerAndLogin(email, password, confirmPassword);

      // Update auth state directly
      ref.read(authStateProvider.notifier).setLoggedIn(true);

      // Success - show message first, then navigate
      if (mounted) {
        _showSuccessSnackBar('Registration successful! Welcome to NANO HR!');
        // Add delay to ensure user sees the success message before navigation
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/attendance');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Registration failed';
        if (e.toString().contains('not found')) {
          errorMessage = 'Email not found in employees database';
        } else if (e.toString().contains('do not match')) {
          errorMessage = 'Passwords do not match';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _performLogin(String email, String password) async {
    try {
      final authService = ref.read(employeeAuthServiceProvider);

      // Show loading
      _showLoadingSnackBar('Authenticating...');

      // Login
      await authService.loginWithEmployeeCredentials(email, password);

      ref.read(authStateProvider.notifier).setLoggedIn(true);

      // Success - show message first, then navigate
      if (mounted) {
        _showSuccessSnackBar('Login successful!');
        // Add delay to ensure user sees the success message before navigation
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/attendance');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        if (e.toString().contains('No employee found')) {
          errorMessage = 'No employee found with this email address';
        } else if (e.toString().contains('Invalid password')) {
          errorMessage = 'Invalid password';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        _showErrorSnackBar(errorMessage);
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
      backgroundColor: AppTheme.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'assets/icon/super1.jpg',
                            height: 100,
                            width: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 60,
                                color: Color(0xFFFD8E00),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'NANO HR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Mode indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _showRegistration
                      ? AppTheme.kNanoGold.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showRegistration ? AppTheme.kNanoGold : Colors.blue,
                    width: 1,
                  ),
                ),
                child: Text(
                  _showRegistration
                      ? 'New Employee Registration'
                      : 'Employee Login',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showRegistration ? AppTheme.kNanoGold : Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Login form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Email field
                    _buildTextField(
                      controller: _email,
                      label: 'Employee Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // Password field
                    _buildTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
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
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPassword,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
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

                    const SizedBox(height: 30),

                    // Login button
                    _buildActionButton(),

                    const SizedBox(height: 20),

                    // Toggle between login and registration
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showRegistration = !_showRegistration;
                          _password.clear();
                          _confirmPassword.clear();
                        });
                      },
                      child: Text(
                        _showRegistration
                            ? 'Already registered? Click here to Login'
                            : 'New Employee? Register here',
                        style: const TextStyle(
                          color: AppTheme.kNanoGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _showRegistration ? 'Register & Login' : 'Login',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
