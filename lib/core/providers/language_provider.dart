import 'package:flutter_riverpod/flutter_riverpod.dart';

// Language state notifier
class LanguageNotifier extends StateNotifier<bool> {
  LanguageNotifier() : super(true); // true = Thai, false = English

  void toggleLanguage() {
    state = !state;
  }

  void setLanguage(bool isThai) {
    state = isThai;
  }

  // Helper method for translation
  String translate(String thaiText, String englishText) {
    return state ? thaiText : englishText;
  }
}

// Global language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, bool>((ref) {
  return LanguageNotifier();
});

// Translation helper provider
final translationProvider = Provider<String Function(String, String)>((ref) {
  final isThai = ref.watch(languageProvider);
  return (String thaiText, String englishText) {
    return isThai ? thaiText : englishText;
  };
});
