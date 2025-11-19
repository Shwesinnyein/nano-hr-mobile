import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/employee_login_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Minimum display time to ensure splash is visible
    await Future.delayed(const Duration(milliseconds: 1500));

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFC7A27B).withOpacity(0.15),
              AppTheme.kBackground,
              const Color(0xFFC7A27B).withOpacity(0.08),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacing
              const Spacer(flex: 2),
              
              // Logo with fade-in animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/nano-icon-square.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Subtitle with fade-in
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'NANO HR SYSTEM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kOnBackground,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart HR for modern teams',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.kOnBackground.withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Clean loading animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
                  ),
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
