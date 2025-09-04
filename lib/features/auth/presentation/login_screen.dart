import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../app/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  void _handleLogin() {
    final email = _email.text.trim();
    final password = _password.text.trim();

    // Basic validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Email format validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Call login
    ref.read(authStateProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        data: (loggedIn) {
          if (loggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            context.go('/attendance');
          }
        },
        error: (e, _) {
          String errorMessage = 'Login failed';
          if (e.toString().contains('Sign in failed')) {
            errorMessage = 'Invalid email or password';
          } else if (e.toString().contains('network')) {
            errorMessage = 'Network error. Please check your connection.';
          } else if (e.toString().contains('timeout')) {
            errorMessage = 'Request timeout. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: const LinearGradient(
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
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icon/nano-store-dark.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 40,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NANO HR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Welcome text
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kOnBackground,
                ),
              ),

              const SizedBox(height: 40),

              // Login form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Username field
                    Container(
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
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password field
                    Container(
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
                        controller: _password,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
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
                      ),
                    ),

                    // const SizedBox(height: 20),

                    // // Remember me and forgot password
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Row(
                    //       children: [
                    //         Checkbox(
                    //           value: _rememberMe,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               _rememberMe = value ?? false;
                    //             });
                    //           },
                    //           activeColor: AppTheme.kNanoGold,
                    //         ),
                    //         const Text(
                    //           'Remember me',
                    //           style: TextStyle(color: Colors.grey),
                    //         ),
                    //       ],
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         // Handle forgot password
                    //       },
                    //       child: const Text(
                    //         'Forget password?',
                    //         style: TextStyle(
                    //           color: AppTheme.kNanoGold,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 30),

                    // Login button
                    Container(
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
                        onPressed: auth.isLoading ? null : () => _handleLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // const SizedBox(height: 20),

                    // // Sign up link
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     const Text(
                    //       'New user? ',
                    //       style: TextStyle(color: Colors.grey),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         // Handle sign up navigation
                    //       },
                    //       child: const Text(
                    //         'Sign Up',
                    //         style: TextStyle(
                    //           color: AppTheme.kNanoGold,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 30),

                    // OR divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.grey)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Employee login button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/employee-login');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppTheme.kNanoGold,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Employee Login',
                          style: TextStyle(
                            color: AppTheme.kNanoGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Social login buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // _buildSocialButton(Icons.g_mobiledata, 'Google'),
                        // _buildSocialButton(Icons.facebook, 'Facebook'),
                        _buildSocialButton(Icons.phone, 'Phone'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Sign in with another account',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
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

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.kNavyBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          // Handle social login
        },
        icon: Icon(icon, color: AppTheme.kNanoGold, size: 24),
      ),
    );
  }
}
