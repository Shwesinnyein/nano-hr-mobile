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
import '../core/widgets/main_layout.dart';
import '../core/services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
          final maxDaysStr = state.uri.queryParameters['maxDays'] ?? '0';
          final maxDays = int.tryParse(maxDaysStr) ?? 0;
          return LeaveRequestScreen(
            leaveType: leaveType,
            leaveTypeName: leaveTypeName,
            maxDays: maxDays,
          );
        },
      ),
      GoRoute(path: '/leave/list', builder: (_, __) => const LeaveListScreen()),
      GoRoute(
        path: '/leave/approval',
        builder: (_, __) => const LeaveApprovalScreen(),
      ),
    ],
    redirect: (context, state) {
      // Redirect from splash to employee login
      if (state.matchedLocation == '/splash') return '/login';

      // Check authentication for protected routes
      final authService = ref.read(authServiceProvider);
      final isAuthenticated = authService.isAuthenticated;

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

      return null;
    },
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
