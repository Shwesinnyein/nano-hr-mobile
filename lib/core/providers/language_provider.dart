import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageNotifier extends StateNotifier<bool> {
  LanguageNotifier() : super(true); 

  void toggleLanguage() {
    state = !state;
  }

  void setLanguage(bool isThai) {
    state = isThai;
  }

  String translate(String thaiText, String englishText) {
    return state ? thaiText : englishText;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, bool>((ref) {
  return LanguageNotifier();
});

final translationProvider = Provider<String Function(String, String)>((ref) {
  final isThai = ref.watch(languageProvider);
  return (String thaiText, String englishText) {
    return isThai ? thaiText : englishText;
  };
});
