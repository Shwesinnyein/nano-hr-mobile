import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class BranchTranslations {
  // Branch name translations
  // Key: English name (name), Value: Thai translation (name_th)
  static const Map<String, String> _branchTranslations = {
    'Office': 'สำนักงาน',
    '001 Chalong': '001 ฉลอง',
    '002 Thepharak': '002 เทพารักษ์',
    '003 Vacharaphol': '003 วัชรพล',
    '004 Nawamin': '004 นวมินทร์',
    '005 Srinagarindra': '005 ศรีนครินทร์',
    '006 Ratchadaphisek 19': '006 รัชดาภิเษก 19',
    '007 PTT Bang Phli': '007 PTT Bang Phli',
    'Sugar Daddy': 'สุกัญญา',
    'Huapan': 'หัวปัน',
  };

  /// Translate branch name based on current language
  /// Returns translated name if available, otherwise returns original name
  static String translateBranchName(WidgetRef ref, String? branchName) {
    if (branchName == null || branchName.isEmpty) {
      return '-';
    }

    // Get current language
    final isThai = ref.read(languageProvider);
    
    // If English, return original
    if (!isThai) {
      return branchName;
    }

    // Check if translation exists
    final translation = _branchTranslations[branchName];
    if (translation == null) {
      // No translation found, return original
      return branchName;
    }

    return translation;
  }

  /// Translate branch name with boolean language flag
  static String translateBranchNameWithLanguage(bool isThai, String? branchName) {
    if (branchName == null || branchName.isEmpty) {
      return '-';
    }

    // If English, return original
    if (!isThai) {
      return branchName;
    }

    final translation = _branchTranslations[branchName];
    if (translation == null) {
      return branchName;
    }

    return translation;
  }

  /// Get all available branch names
  static List<String> getAvailableBranches() {
    return _branchTranslations.keys.toList();
  }
}

