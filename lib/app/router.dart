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
import '../features/notifications/presentation/notification_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../core/widgets/main_layout.dart';

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
          return LeaveRequestScreen(leaveType: leaveType);
        },
      ),
      GoRoute(path: '/leave/list', builder: (_, __) => const LeaveListScreen()),
    ],
    redirect: (context, state) {
      // Redirect from splash to employee login
      if (state.matchedLocation == '/splash') return '/login';
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

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
