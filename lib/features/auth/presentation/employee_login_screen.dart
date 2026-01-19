import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/language_provider.dart';
import '../data/auth_repository.dart' as auth_repo;
// import 'forgot_password_screen.dart';

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
  bool _useMobileAPI = true; 

  
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
      
      if (_password.text != _confirmPassword.text) {
        _showErrorSnackBar('Passwords do not match');
        return;
      }
      _performRegistration(_email.text, _password.text, _confirmPassword.text);
    } else {
      
      _performLogin(_email.text, _password.text);
    }
  }

  void _performRegistration(
    String email,
    String password,
    String confirmPassword,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      
      final result = await authService.registerUser(
        email,
        password,
        confirmPassword,
      );

      if (result['success'] == true) {
        
        ref
            .read(authServiceProvider)
            .setCurrentUser('user-${DateTime.now().millisecondsSinceEpoch}');

        
        if (mounted) {
          _showSuccessSnackBar('Registration successful! Welcome to NANO HR!');
          _showRegistration = false;
          
          if (mounted) {
            context.go('/employee-login');
          }
          
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        
        if (errorMessage.contains('EMAIL_ALREADY_IN_FIREBASE_AUTH')) {
          _showEmailAlreadyRegisteredAlert();
        }
        
        else if (errorMessage.contains('EMAIL_NOT_FOUND_IN_EMPLOYEE_TABLE')) {
          _showEmailNotFoundInEmployeeTableAlert();
        } else {
          
          _showErrorSnackBar(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _performLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
    });
    print('performLogin: email=$email, password=***');
    try {
      final authController = ref.read(auth_repo.authStateProvider.notifier);

      
      await authController.loginMobile(email, password);

      final authService = ref.read(authServiceProvider);

      if (mounted) {

        _showSuccessSnackBar('Login successful!');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/attendance');
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        final errorMessage = e.toString();
        print(errorMessage);
        if (errorMessage.contains('PASSWORD_INCORRECT')) {
          _showPasswordIncorrectAlert();
        }
        else if (errorMessage.contains('EMAIL_EXISTS_IN_EMPLOYEE_TABLE')) {
          _showEmailExistsInEmployeeTableAlert();
        } 
        else if (errorMessage.contains('EMAIL_NOT_FOUND_IN_SYSTEM')) {
          _showEmailNotFoundAlert();
        }
        else if (errorMessage.contains('You need to register first') || 
            errorMessage.contains('user-not-found')) {
          _showRegistrationRequiredAlert();
        } else {
          _showErrorSnackBar(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _showRegistrationRequiredAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'บัญชีไม่พบ', 'Account Not Found'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          content: Text(
            _t(
              ref,
              'อีเมลนี้ยังไม่ได้ลงทะเบียนในระบบ\nกรุณาลงทะเบียนก่อนเข้าสู่ระบบ',
              'This email is not registered in the system.\nPlease register first before logging in.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showRegistration = true;
                });
              },
              child: Text(
                _t(ref, 'ลงทะเบียน', 'Register'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ปิด', 'Close'),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailExistsInEmployeeTableAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'อีเมลพบในระบบ', 'Email Found in System'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.kNanoGold,
            ),
          ),
          content: Text(
            _t(
              ref,
              'อีเมลนี้พบในระบบพนักงานแล้ว แต่ยังไม่ได้ลงทะเบียนในระบบ\nกรุณาลงทะเบียนเพื่อสร้างบัญชีและเข้าสู่ระบบ',
              'This email is found in the employee system but not yet registered.\nPlease register to create your account and login.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showRegistration = true;
                });
              },
              child: Text(
                _t(ref, 'ลงทะเบียน', 'Register'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ปิด', 'Close'),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailNotFoundAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'อีเมลไม่พบในระบบ', 'Email Not Found'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          content: Text(
            _t(
              ref,
              'อีเมลนี้ไม่พบในระบบพนักงาน\nกรุณาติดต่อ HR เพื่อเพิ่มอีเมลของคุณในระบบ',
              'This email is not found in the employee system.\nPlease contact HR to add your email to the system.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ตกลง', 'OK'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPasswordIncorrectAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'รหัสผ่านไม่ถูกต้อง', 'Password Incorrect'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          content: Text(
            _t(
              ref,
              'รหัสผ่านที่คุณป้อนไม่ถูกต้อง\nกรุณาตรวจสอบรหัสผ่านและลองอีกครั้ง',
              'The password you entered is incorrect.\nPlease check your password and try again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ตกลง', 'OK'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailAlreadyRegisteredAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'อีเมลลงทะเบียนแล้ว', 'Email Already Registered'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          content: Text(
            _t(
              ref,
              'อีเมลนี้ได้ลงทะเบียนในระบบแล้ว\nกรุณาเข้าสู่ระบบแทน',
              'This email is already registered in the system.\nPlease login instead.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  
                setState(() {
                  _showRegistration = false;
                });
              },
              child: Text(
                _t(ref, 'เข้าสู่ระบบ', 'Login'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ปิด', 'Close'),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailNotFoundInEmployeeTableAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t(ref, 'อีเมลไม่พบในระบบ', 'Email Not Found'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          content: Text(
            _t(
              ref,
              'อีเมลนี้ไม่พบในระบบพนักงาน\nกรุณาติดต่อ HR เพื่อเพิ่มอีเมลของคุณในระบบก่อนลงทะเบียน',
              'This email is not found in the employee system.\nPlease contact HR to add your email to the system before registering.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                _t(ref, 'ตกลง', 'OK'),
                style: const TextStyle(
                  color: AppTheme.kNanoGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // void _handleForgotPassword() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const ForgotPasswordScreen(),
  //     ),
  //   );
  // }

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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFc7a27b), 
                const Color(0xFFb8956b), 
                const Color(0xFFa0855a), 
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildLanguageSwitch()],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        _buildModernLogo(),

                        const SizedBox(height: 20),

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
                                _buildModernModeIndicator(),

                                const SizedBox(height: 20),

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

                                // Forgot Password link (only show in login mode)
                                // if (!_showRegistration) ...[
                                //   const SizedBox(height: 12),
                                //   Align(
                                //     alignment: Alignment.centerRight,
                                //     child: TextButton(
                                //       onPressed: _handleForgotPassword,
                                //       style: TextButton.styleFrom(
                                //         padding: const EdgeInsets.symmetric(
                                //           horizontal: 8,
                                //           vertical: 4,
                                //         ),
                                //       ),
                                //       child: Text(
                                //         _t(
                                //           ref,
                                //           'ลืมรหัสผ่าน?',
                                //           'Forgot Password?',
                                //         ),
                                //         style: TextStyle(
                                //           color: AppTheme.kNanoGold,
                                //           fontSize: 14,
                                //           fontWeight: FontWeight.w600,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ],

                                const SizedBox(height: 24),

                                _buildModern3DButton(),

                                const SizedBox(height: 24),

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
      ),
    );
  }

  Widget _buildModernLogo() {
    return Column(
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icon/nano-store3.png',
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
        const SizedBox(height: 24),
        Text(
          _t(ref, 'NANO Work', 'NANO Work'),
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.w700, 
            color: Colors.white,
            letterSpacing: 1.5, 
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 50, 
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12), 
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
          fontSize: 15, 
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8), 
            padding: const EdgeInsets.all(6), 
            decoration: BoxDecoration(
              color: const Color(0xFFc7a27b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), 
            ),
            child: Icon(
              icon,
              color: const Color(0xFFc7a27b),
              size: 18,
            ), 
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
            horizontal: 16, 
            vertical: 12, 
          ),
        ),
      ),
    );
  }

  Widget _buildModern3DButton() {
    return Container(
      width: double.infinity,
      height: 52, 
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
        onPressed: _isLoading
            ? null
            : (_showRegistration ? _handleRegistration : _handleLogin),
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
                    size: 18, 
                  ),
                  const SizedBox(width: 6), 
                  Text(
                    _showRegistration
                        ? _t(ref, 'สร้างบัญชี', 'Create Account')
                        : _t(ref, 'เข้าสู่ระบบ', 'Sign In'),
                    style: const TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.w700, 
                      color: Colors.white,
                      letterSpacing: 0.5, 
                      shadows: const [
                        Shadow(
                          color: Color(
                            0x4D000000,
                          ), 
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

  Future<void> _handleRegistration() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    _performRegistration(_email.text, _password.text, _confirmPassword.text);
  }

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
