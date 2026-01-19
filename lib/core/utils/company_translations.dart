import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class CompanyTranslations {
  // Company name translations
  static const Map<String, Map<String, String>> _companyTranslations = {
    'NANO-VIP': {
      'th': 'บริษัท นาโน วีไอพี คาร์ แอนด์ ไดรเวอร์ จํากัด',
      'en': 'NANO-VIP CAR AND DRIVER COMPANY LIMITED',
    },
    'NANO-STORES': {
      'th': 'บริษัท นาโน สโตร์ส จำกัด',
      'en': 'NANO-STORES COMPANY LIMITED',
    },
    'NANO-ENTERTAINMENT': {
      'th': 'บริษัท นาโน เอ็นเตอร์เทนเม้นท์ จํากัด',
      'en': 'NANO-ENTERTAINMENT COMPANY LIMITED',
    },
  };

  /// Translate company name based on current language
  /// Returns translated name if available, otherwise returns original name
  static String translateCompanyName(WidgetRef ref, String? companyName) {
    if (companyName == null || companyName.isEmpty) {
      return '-';
    }

    // Check if translation exists
    final translations = _companyTranslations[companyName.toUpperCase()];
    if (translations == null) {
      // No translation found, return original
      return companyName;
    }

    // Get current language
    final isThai = ref.read(languageProvider);
    return isThai ? translations['th']! : translations['en']!;
  }

  /// Translate company name with boolean language flag
  static String translateCompanyNameWithLanguage(bool isThai, String? companyName) {
    if (companyName == null || companyName.isEmpty) {
      return '-';
    }

    final translations = _companyTranslations[companyName.toUpperCase()];
    if (translations == null) {
      return companyName;
    }

    return isThai ? translations['th']! : translations['en']!;
  }

  /// Get all available company names
  static List<String> getAvailableCompanies() {
    return _companyTranslations.keys.toList();
  }
}

