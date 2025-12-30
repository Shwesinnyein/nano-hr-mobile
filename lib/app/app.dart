import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrader/upgrader.dart';
import 'router.dart';
import 'theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'NANO HR',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false, // Hide debug banner in all modes
      builder: (context, child) {
        return UpgradeAlert(
          upgrader: Upgrader(
            // Set minimum required version - users below this version will be forced to update
            // Update this value when you need to force users to update
            // Current: '1.0.8' - forces users on 1.0.7 or below to update
            // When 1.1.0 is published, you can change this to '1.1.0' to force all users to update
            minAppVersion: '1.0.8',
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
