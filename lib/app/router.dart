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
import '../core/widgets/main_layout.dart';
import '../features/auth/data/auth_repository.dart' as auth_repo;

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
    ],
    redirect: (context, state) async {
      // Check authentication for protected routes using AuthRepository
      final authState = ref.read(auth_repo.authStateProvider);
      
      // Handle splash screen - wait for auth state to resolve
      if (state.matchedLocation == '/splash') {
        return authState.when(
          data: (loggedIn) => loggedIn ? '/attendance' : '/login',
          loading: () => null, // Stay on splash while loading
          error: (_, __) => '/login',
        );
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
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/employee-login')) {
        return '/attendance';
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
