import 'package:flutter_riverpod/flutter_riverpod.dart';

class OTPNotifier extends StateNotifier<String?> {
  OTPNotifier() : super(null);

  void setOTP(String otp) {
    state = otp;
  }

  void clearOTP() {
    state = null;
  }
}

final otpProvider = StateNotifierProvider<OTPNotifier, String?>((ref) {
  return OTPNotifier();
});

