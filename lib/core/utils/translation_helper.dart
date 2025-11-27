import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class TranslationHelper {
  static String t(WidgetRef ref, String thaiText, String englishText) {
    final isThai = ref.watch(languageProvider);
    return isThai ? thaiText : englishText;
  }

  static String translate(bool isThai, String thaiText, String englishText) {
    return isThai ? thaiText : englishText;
  }
}

extension TranslationExtension on WidgetRef {
  String t(String thaiText, String englishText) {
    return TranslationHelper.t(this, thaiText, englishText);
  }
}
