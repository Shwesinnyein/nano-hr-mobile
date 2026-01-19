import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class LocationTranslations {
  // Location name translations
  // Key: English name (name), Value: Thai translation (name_th)
  static const Map<String, String> _locationTranslations = {
    'Bangkok': 'กรุงเทพ',
    'Phuket': 'ภูเก็ต',
  };

  /// Translate location name based on current language
  /// Returns translated name if available, otherwise returns original name
  static String translateLocationName(WidgetRef ref, String? locationName) {
    if (locationName == null || locationName.isEmpty) {
      return '-';
    }

    // Get current language
    final isThai = ref.read(languageProvider);
    
    // If English, return original
    if (!isThai) {
      return locationName;
    }

    // Check if translation exists
    final translation = _locationTranslations[locationName];
    if (translation == null) {
      // No translation found, return original
      return locationName;
    }

    return translation;
  }

  /// Translate location name with boolean language flag
  static String translateLocationNameWithLanguage(bool isThai, String? locationName) {
    if (locationName == null || locationName.isEmpty) {
      return '-';
    }

    // If English, return original
    if (!isThai) {
      return locationName;
    }

    final translation = _locationTranslations[locationName];
    if (translation == null) {
      return locationName;
    }

    return translation;
  }

  /// Get all available location names
  static List<String> getAvailableLocations() {
    return _locationTranslations.keys.toList();
  }
}

