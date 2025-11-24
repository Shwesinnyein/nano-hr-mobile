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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    if (_hasInitializedNotifications) return;

    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated) {
      ref.read(notificationProvider.notifier).initialize();
      _hasInitializedNotifications = true;
    }
  }

  @override
  Widget build(BuildContext context) {
   
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
