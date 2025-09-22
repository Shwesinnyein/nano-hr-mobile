import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';

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
      _showLoadingSnackBar('Setting up your account...');

      // Register using API
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
      backgroundColor: AppTheme.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                height: 250,
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
                        height: 130,
                        width: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppTheme.kNanoGold.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/icon/nano-store-dark.png',
                            height: 110,
                            width: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 70,
                                color: AppTheme.kNanoGold,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'NANO HR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          shadows: [
                            const Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 3),
                              blurRadius: 6,
                            ),
                            Shadow(
                              color: AppTheme.kNanoGold.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
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
