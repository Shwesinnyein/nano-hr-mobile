import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/version_check_service.dart';
import '../providers/language_provider.dart';

class CustomUpdateAlert extends ConsumerStatefulWidget {
  final Widget child;
  final String minAppVersion;
  final String? appStoreUrl;
  final String? playStoreUrl;

  const CustomUpdateAlert({
    super.key,
    required this.child,
    required this.minAppVersion,
    this.appStoreUrl,
    this.playStoreUrl,
  });

  @override
  ConsumerState<CustomUpdateAlert> createState() => _CustomUpdateAlertState();
}

class _CustomUpdateAlertState extends ConsumerState<CustomUpdateAlert> {
  final VersionCheckService _versionCheckService = VersionCheckService();
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) return;
    
    // Wait for the app to fully load before checking for updates (non-blocking)
    // Increased to 5 seconds to not interfere with initial app loading
    await Future.delayed(const Duration(seconds: 5));
    
    if (!mounted) return;
    
    final result = await _versionCheckService.checkForUpdate(
      minAppVersion: widget.minAppVersion,
    );

    if (mounted && result['shouldUpdate'] == true) {
      setState(() {
        _hasChecked = true;
      });

      // Show update dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog(result);
      });
    } else {
      setState(() {
        _hasChecked = true;
      });
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    final isMandatory = updateInfo['isMandatory'] == true;
    final latestVersion = updateInfo['latestVersion'] as String;
    final currentVersion = updateInfo['currentVersion'] as String;
    final updateMessage = updateInfo['updateMessage'] as String?;
    final updateMessageTh = updateInfo['updateMessageTh'] as String?;
    final updateUrl = updateInfo['updateUrl'] as Map<String, dynamic>?;
    
    // Store updateUrl for later use
    _updateUrl = updateUrl;

    // Get current language state - read from provider
    final isThai = ref.read(languageProvider);
    
    // Select message based on language
    final message = isThai && updateMessageTh != null && updateMessageTh.isNotEmpty
        ? updateMessageTh
        : (updateMessage ?? 'A new version ($latestVersion) is available. Please update to continue using the app.');

    showDialog(
      context: context,
      barrierDismissible: !isMandatory, // Can't dismiss if mandatory
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: !isMandatory, // Can't close if mandatory
          child: AlertDialog(
            title: Text(isThai ? 'อัปเดตแอป' : 'Update Available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 12),
                Text(
                  '${isThai ? 'เวอร์ชันปัจจุบัน' : 'Current version'}: $currentVersion',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${isThai ? 'เวอร์ชันล่าสุด' : 'Latest version'}: $latestVersion',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(isThai ? 'ภายหลัง' : 'Later'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openStore(updateUrl);
                },
                child: Text(isThai ? 'อัปเดตตอนนี้' : 'Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _updateUrl;

  Future<void> _openStore(Map<String, dynamic>? updateUrl) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = Theme.of(context).platform;
    
    String? storeUrl;
    
    // Priority 1: Use updateUrl from API response
    if (updateUrl != null) {
      if (platform == TargetPlatform.iOS) {
        storeUrl = updateUrl['ios'] as String?;
      } else if (platform == TargetPlatform.android) {
        storeUrl = updateUrl['android'] as String?;
      }
    }
    
    // Priority 2: Use widget URLs
    if (storeUrl == null || storeUrl.isEmpty) {
      if (platform == TargetPlatform.iOS) {
        storeUrl = widget.appStoreUrl;
      } else if (platform == TargetPlatform.android) {
        storeUrl = widget.playStoreUrl;
      }
    }
    
    // Priority 3: Fallback to package name
    if (storeUrl == null || storeUrl.isEmpty) {
      if (platform == TargetPlatform.iOS) {
        storeUrl = 'https://apps.apple.com/app/id${packageInfo.packageName}';
      } else if (platform == TargetPlatform.android) {
        storeUrl = 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
      }
    }

    if (storeUrl != null && storeUrl.isNotEmpty) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

