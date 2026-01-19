import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class GenderTranslations {
  // Gender translations
  static const Map<String, String> _genderTranslations = {
    'Male': 'ผู้ชาย',
    'male': 'ผู้ชาย',
    'MALE': 'ผู้ชาย',
    'Female': 'ผู้หญิง',
    'female': 'ผู้หญิง',
    'FEMALE': 'ผู้หญิง',
  };

  /// Translate gender based on current language
  /// Returns translated gender if available, otherwise returns original
  static String translateGender(WidgetRef ref, String? gender) {
    if (gender == null || gender.isEmpty) {
      return '-';
    }

    // Get current language
    final isThai = ref.read(languageProvider);
    
    // If English, return original
    if (!isThai) {
      return gender;
    }

    // Check if translation exists (case-insensitive)
    final translation = _genderTranslations[gender] ?? 
                       _genderTranslations[gender.toLowerCase()] ??
                       _genderTranslations[gender.toUpperCase()];
    
    if (translation == null) {
      // No translation found, return original
      return gender;
    }

    return translation;
  }

  /// Translate gender with boolean language flag
  static String translateGenderWithLanguage(bool isThai, String? gender) {
    if (gender == null || gender.isEmpty) {
      return '-';
    }

    // If English, return original
    if (!isThai) {
      return gender;
    }

    final translation = _genderTranslations[gender] ?? 
                       _genderTranslations[gender.toLowerCase()] ??
                       _genderTranslations[gender.toUpperCase()];
    
    if (translation == null) {
      return gender;
    }

    return translation;
  }
}

