import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(currentIndex: currentIndex),
    );
  }
}
