import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/employee_login_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/attendance/presentation/attendance_calendar_screen.dart';
import '../features/leave/presentation/leave_balance_screen.dart';
import '../features/leave/presentation/leave_request_screen.dart';
import '../features/leave/presentation/leave_screen.dart';
import '../features/leave/presentation/leave_list_screen.dart';
import '../features/leave/presentation/leave_approval_screen.dart';
import '../features/notifications/presentation/notification_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../core/widgets/main_layout.dart';
import '../features/auth/data/auth_repository.dart' as auth_repo;
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(auth_repo.authStateProvider.notifier).authStream,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const EmployeeLoginScreen()),
      GoRoute(
        path: '/employee-login',
        builder: (_, __) => const EmployeeLoginScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (_, __) =>
            const MainLayout(currentIndex: 0, child: AttendanceScreen()),
      ),
      GoRoute(
        path: '/attendance/calendar',
        builder: (_, __) => const AttendanceCalendarScreen(),
      ),
      GoRoute(
        path: '/leave',
        builder: (_, __) =>
            const MainLayout(currentIndex: 1, child: LeaveScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) =>
            const MainLayout(currentIndex: 2, child: NotificationScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) =>
            const MainLayout(currentIndex: 3, child: ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) =>
            const MainLayout(currentIndex: 4, child: SettingsScreen()),
      ),
      GoRoute(
        path: '/leave/balance',
        builder: (_, __) => const LeaveBalanceScreen(),
      ),
      GoRoute(
        path: '/leave/request/:leaveType',
        builder: (context, state) {
          final leaveType = state.pathParameters['leaveType'] ?? 'annual';
          final leaveTypeName = state.uri.queryParameters['name'] ?? '';
          final leaveTypeNameEng = state.uri.queryParameters['engName'] ?? '';
          final maxDaysStr = state.uri.queryParameters['maxDays'] ?? '0';
          final maxDays = int.tryParse(maxDaysStr) ?? 0;
          return LeaveRequestScreen(
            leaveType: leaveType,
            leaveTypeName: leaveTypeName,
            maxDays: maxDays,
            leaveTypeNameEng: leaveTypeNameEng,
          );
        },
      ),
      GoRoute(path: '/leave/list', builder: (_, __) => const LeaveListScreen()),
      GoRoute(
        path: '/leave/approval',
        builder: (_, __) => const LeaveApprovalScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
    ],
    redirect: (context, state) async {
      // Check authentication for protected routes using AuthRepository
      final authState = ref.read(auth_repo.authStateProvider);
      
      // Splash screen handles its own navigation with minimum display time
      if (state.matchedLocation == '/splash') {
        return null; // Stay on splash - it will navigate itself
      }

      final isAuthenticated = authState.when(
        data: (loggedIn) => loggedIn,
        loading: () => false, // While loading, treat as not authenticated for protected routes
        error: (_, __) => false,
      );

      // List of protected routes that require authentication
      final protectedRoutes = [
        '/attendance',
        '/leave',
        '/notifications',
        '/profile',
        '/settings',
      ];
      final isProtectedRoute = protectedRoutes.any(
        (route) => state.matchedLocation.startsWith(route),
      );

      // If trying to access protected route without authentication, redirect to login
      if (isProtectedRoute && !isAuthenticated) {
        return '/login';
      }

      // If logged in and trying to access login page, redirect to attendance
      // But only if auth state is fully resolved (not loading)
      if (!authState.isLoading && isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/employee-login')) {
        return '/attendance';
      }
      
      // If auth is still loading and on login page, stay on login (don't redirect yet)
      if (authState.isLoading &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/employee-login')) {
        return null; // Stay on login while loading
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoDropAnimation;
  late Animation<double> _logoBounceAnimation;
  late Animation<double> _logoNameSlideAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    // Logo/content animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    // Logo drop animation (drop from top)
    _logoDropAnimation = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );
    // Logo bounce animation (bounce after landing)
    _logoBounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.elasticOut),
      ),
    );
    // Logo name slide animation (slide in from right)
    _logoNameSlideAnimation = Tween<double>(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    
    // Background animation (gradient shift + pulse)
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // Loop continuously
    
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Dots animation (staggered bounce effect)
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotsController,
          curve: Interval(
            index * 0.2, // Stagger each dot
            (index * 0.2) + 0.6,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
    
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Minimum display time to ensure splash is visible (3.5 seconds)
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    // Wait for auth state to fully resolve (no loading state)
    var authState = ref.read(auth_repo.authStateProvider);
    int maxWaitAttempts = 10; // Maximum 5 seconds (10 * 500ms)
    int attempts = 0;
    
    // Keep waiting until auth state is resolved (not loading)
    while (authState.isLoading && attempts < maxWaitAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      authState = ref.read(auth_repo.authStateProvider);
      attempts++;
    }

    if (!mounted) return;

    // Navigate based on auth state (should be resolved by now)
    final targetRoute = authState.when(
      data: (loggedIn) => loggedIn ? '/attendance' : '/login',
      loading: () => '/login', // Fallback if still loading after max attempts
      error: (_, __) => '/login',
    );

    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          // Animated gradient colors that shift
          final gradientValue = _gradientAnimation.value;
          final pulseValue = _pulseAnimation.value;
          
          // Calculate animated colors (shifting between different opacities)
          // More visible animation: opacity ranges from 0.08 to 0.25
          final topColorOpacity = 0.08 + (0.25 - 0.08) * (0.5 + 0.5 * (gradientValue * 2 - 1).abs());
          final bottomColorOpacity = 0.05 + (0.20 - 0.05) * (0.5 + 0.5 * (gradientValue * 2 - 1).abs());
          
          // Animated gradient direction for more visible effect
          final beginX = -1.0 + 2.0 * gradientValue; // Animate from -1 to 1
          final beginY = -1.0 + 2.0 * (1.0 - gradientValue); // Opposite direction
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(beginX * 0.5, beginY * 0.5), // Subtle movement
                end: Alignment(-beginX * 0.5, -beginY * 0.5),
                colors: [
                  // Beige/cream gradient (lighter at top, warmer at bottom)
                  Color(0xFFF5F0E8), // Light beige (top)
                  Color(0xFFE8DDD0), // Warmer beige (middle)
                  Color(0xFFE0D5C8), // Slightly darker warm beige (bottom)
                ],
                stops: [
                  0.0,
                  0.4 + 0.2 * gradientValue, // More animated stop position
                  1.0,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacing
              const Spacer(flex: 2),
              
              // Logo icon - drops from top
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final dropY = _logoDropAnimation.value;
                  final bounce = _logoBounceAnimation.value;
                  
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, dropY),
                      child: Transform.scale(
                        scale: bounce,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/icon/nano-store3.png',
                              width: 100,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 15),
              
              // // Logo name - slides in from right
               AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final slideX = _logoNameSlideAnimation.value;
                  
                  return Opacity(
                    opacity: slideX < 200 ? 1.0 : 0.0,
                    child: Transform.translate(
                      offset: Offset(slideX, 0),
                      child: Text(
                        'NANO HR SYSTEM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kOnBackground,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // AnimatedBuilder(
              //   animation: _controller,
              //   builder: (context, child) {
              //     final slideX = _logoNameSlideAnimation.value;
                  
              //     return Opacity(
              //       opacity: slideX < 200 ? 1.0 : 0.0,
              //       child: Transform.translate(
              //         offset: Offset(slideX, 0),
              //         child: Image.asset(
              //           'assets/icon/logo-name.png',
              //           width: 320,
              //           height: 90,
              //           fit: BoxFit.contain,
              //         ),
              //       ),
              //     );
              //   },
              // ),
              
             // const SizedBox(height: 10),
              
              // Subtitle with fade-in - commented out
              // FadeTransition(
              //   opacity: _fadeAnimation,
              //   child: Column(
              //     children: [
              //       Text(
              //         'NANO HR SYSTEM',
              //         style: TextStyle(
              //           fontSize: 18,
              //           fontWeight: FontWeight.bold,
              //           color: AppTheme.kOnBackground,
              //           letterSpacing: 1.2,
              //         ),
              //       ),
              //       const SizedBox(height: 6),
              //       Text(
              //         'Smart HR for modern teams',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w400,
              //           color: AppTheme.kOnBackground.withOpacity(0.6),
              //           letterSpacing: 0.5,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              
              const SizedBox(height: 8),
              
              // Animated dots (•••)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _dotAnimations[index],
                      builder: (context, child) {
                        final scale = 0.5 + (_dotAnimations[index].value * 0.5); // Scale from 0.5 to 1.0
                        final opacity = 0.3 + (_dotAnimations[index].value * 0.7); // Opacity from 0.3 to 1.0
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.kNanoGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              
              // Bottom spacing
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
