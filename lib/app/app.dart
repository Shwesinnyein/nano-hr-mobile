import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/widgets/custom_update_alert.dart';

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
        return CustomUpdateAlert(
          // Set minimum required version - users below this version will be forced to update
          // Current: '1.1.1' - forces ALL users on older versions (1.0.x, 1.1.0) to update
          // When you publish a new version (e.g., 1.1.2), update this to '1.1.2' to force all users to update
          minAppVersion: '1.1.1',
          // Add your App Store and Play Store URLs here
          // appStoreUrl: 'https://apps.apple.com/app/your-app-id',
          // playStoreUrl: 'https://play.google.com/store/apps/details?id=your.package.name',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
