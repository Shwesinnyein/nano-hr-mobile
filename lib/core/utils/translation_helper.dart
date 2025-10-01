import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

// Global translation helper that can be used anywhere in the app
class TranslationHelper {
  static String t(WidgetRef ref, String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  // Static method that doesn't require ref (for use in non-widget contexts)
  static String translate(bool isThai, String thaiText, String englishText) {
    return isThai ? thaiText : englishText;
  }
}

// Extension for easier usage
extension TranslationExtension on WidgetRef {
  String t(String thaiText, String englishText) {
    return TranslationHelper.t(this, thaiText, englishText);
  }
}
