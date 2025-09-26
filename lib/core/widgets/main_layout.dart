import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bottom_nav_bar.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _hasInitializedNotifications = false;

  @override
  void initState() {
    super.initState();
    // Initialize notifications when the main layout is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    if (_hasInitializedNotifications) return;

    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated) {
      print('🔔 MainLayout: User is authenticated, initializing notifications');
      ref.read(notificationProvider.notifier).initialize();
      _hasInitializedNotifications = true;
    } else {
      print(
        '🔔 MainLayout: User not authenticated, skipping notification initialization',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user becomes authenticated and initialize notifications
    final authService = ref.watch(authServiceProvider);
    if (authService.isAuthenticated && !_hasInitializedNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeNotifications();
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,
      ),
    );
  }
}
